# Copyright (C) 2026.
"""
Tachimanga backup processing tool (integrated v3).

Four modes, one goal each:

  reset       Full wipe for a fresh start.
              Clears library, chapters, history, sync records and account
              credentials, and disables Local Source. Equivalent to a
              brand-new installation.

  history     History removal + backup slimming (combined, one step).
              Keeps only real library books (in_library=1). All residual
              "browsed but never added" Manga rows are deleted, together
              with every orphan row pointing at them. History / Stats /
              UpdateRecord are wiped. All chapters are reset to unread
              with cleared page numbers and timestamps (so the app cannot
              infer "last read chapter"). Repos and Sources with nothing
              attached are removed dynamically (no hard-coded list, so an
              outdated list can cause neither false deletes nor misses).
              Account credentials are cleared.

  resync      Sync state rebuild.
              Keeps library and history intact; only resets the sync
              queue and flags (dirty / commit_id back to zero, SyncState
              / SyncCommit cleared), so the next sync starts from the
              current state as a fresh baseline instead of pushing a huge
              pile of historical commits.

  mark_unread Standalone mode: reset every chapter to unread and clear
              page numbers and timestamps. Can be layered on top of the
              output of other modes such as resync. The history mode
              already includes this step; do not stack it twice.

Account safety rule (applied by every mode):
    The Setting table (which holds account email / token credentials)
    and SyncState (which holds the account email) are always cleared,
    preventing credential leaks when a backup is shared or restores over
    someone else's account.

Sequence reset:
    After processing, every table's SQLite auto-increment sequence
    (sqlite_sequence) is re-aligned to the maximum id of the remaining
    rows, so newly added rows inside the app do not keep counting up
    from a huge stale number or reuse id space left behind by deleted
    rows.

Usage:
    python3 tmb.py <source.tmb> <output.tmb> <reset|history|resync|mark_unread>
"""

import hashlib
import json
import logging
import shutil
import sqlite3
import sys
import tempfile
import time
import zipfile
from pathlib import Path

logging.basicConfig(level=logging.INFO, format="%(message)s")
logger = logging.getLogger(__name__)

SQLITE_MAX_PARAMS = 900


def strip_account_info(cur: sqlite3.Cursor) -> None:
    """Clear account credentials and login-related rows to avoid leaks."""
    cur.execute("DELETE FROM Setting")
    cur.execute("DELETE FROM SyncState")


def _chunks(items: list[int], size: int = SQLITE_MAX_PARAMS) -> list[list[int]]:
    return [items[i : i + size] for i in range(0, len(items), size)]


def cascade_delete_manga(cur: sqlite3.Cursor, drop_ids: list[int]) -> None:
    """Delete orphan rows tied to the given Manga ids, then the Manga rows."""
    if not drop_ids:
        return

    cascade_specs = [
        ("Chapter", "manga"),
        ("CategoryManga", "manga"),
        ("MangaMeta", "manga_ref"),
        ("TrackRecord", "manga_id"),
        ("History", "manga_id"),
        ("ChapterSync", "manga_id"),
        ("Stats", "manga_id"),
    ]
    for table, column in cascade_specs:
        for batch in _chunks(drop_ids):
            placeholders = ",".join("?" * len(batch))
            cur.execute(f"DELETE FROM {table} WHERE {column} IN ({placeholders})", batch)  # noqa: S608 (table/column names are static constants)

    for batch in _chunks(drop_ids):
        placeholders = ",".join("?" * len(batch))
        cur.execute(f"DELETE FROM Manga WHERE id IN ({placeholders})", batch)  # noqa: S608 (static table name)


def prune_empty_repos_and_sources(cur: sqlite3.Cursor) -> None:
    """
    Drop Repos and Sources that have nothing attached any more.

    Determined dynamically by current install/usage state, not by any
    hard-coded list of names.
    """
    # A Source with no Manga attached is removed (id=0 is Local source,
    # handled separately and left untouched here).
    cur.execute(
        """
        DELETE FROM Source
        WHERE id NOT IN (SELECT DISTINCT source FROM Manga)
          AND id != 0
        """
    )

    # A Repo with no installed extension attached is removed.
    cur.execute(
        """
        DELETE FROM Repo
        WHERE id NOT IN (
            SELECT DISTINCT repo_id FROM Extension
            WHERE repo_id IS NOT NULL AND is_installed = 1
        )
        """
    )


def resync_autoincrement_sequences(cur: sqlite3.Cursor) -> None:
    """
    Re-align each table's sqlite_sequence counter with the max id.

    When a table is empty, its sequence row is removed so the next insert
    starts again from 1 instead of a huge stale number.
    """
    cur.execute("SELECT name FROM sqlite_sequence")
    tracked_tables = [row[0] for row in cur.fetchall()]

    for table in tracked_tables:
        # Defensive check: only align tables that still have an id column.
        cur.execute(f"PRAGMA table_info({table})")
        columns = [col[1] for col in cur.fetchall()]
        if "id" not in columns:
            continue

        cur.execute(f"SELECT MAX(id) FROM {table}")  # noqa: S608 (table name comes from sqlite_sequence itself)
        max_id = cur.fetchone()[0]

        if max_id is None:
            cur.execute("DELETE FROM sqlite_sequence WHERE name = ?", (table,))
        else:
            cur.execute(
                "UPDATE sqlite_sequence SET seq = ? WHERE name = ?",
                (max_id, table),
            )


def process_reset(cur: sqlite3.Cursor) -> None:
    """Wipe everything for a fresh-start state."""
    tables_to_wipe = [
        "Manga",
        "Chapter",
        "Page",
        "CategoryManga",
        "ChapterMeta",
        "MangaMeta",
        "TrackRecord",
        "History",
        "SyncCommit",
        "ChapterSync",
        "Stats",
        "SourceMeta",
        "UpdateRecord",
    ]
    for table in tables_to_wipe:
        cur.execute(f"DELETE FROM {table}")  # noqa: S608 (static table name)

    cur.execute("PRAGMA table_info(Extension)")
    extension_columns = [col[1] for col in cur.fetchall()]
    if "is_installed" in extension_columns:
        cur.execute(
            "UPDATE Extension SET is_installed=0 WHERE pkg_name=?",
            ("eu.kanade.tachiyomi.source.local",),
        )
    cur.execute("DELETE FROM Source WHERE id = 0")

    strip_account_info(cur)


def process_history(cur: sqlite3.Cursor) -> None:
    """
    Remove browsing history and slim the backup (keeps in_library=1).

    Steps:
        1. Delete residual "browsed but never added" Manga rows and all
           orphan rows pointing at them.
        2. Wipe History / Stats / UpdateRecord entirely (they describe
           reading progress of in-library books, not orphan data).
        3. Dynamically remove empty Repos / Sources.
        4. Reset every chapter to unread and clear pages / timestamps.
        5. Clear account credentials.
    """
    cur.execute("SELECT id FROM Manga WHERE in_library = 0 OR in_library IS NULL")
    drop_ids = [row[0] for row in cur.fetchall()]
    cascade_delete_manga(cur, drop_ids)

    for table in ["History", "Stats", "UpdateRecord"]:
        cur.execute(f"DELETE FROM {table}")  # noqa: S608 (static table name)

    prune_empty_repos_and_sources(cur)

    process_mark_unread(cur)  # Includes strip_account_info().


def process_resync(cur: sqlite3.Cursor) -> None:
    """Reset only the sync queue and flags; keep library and history."""
    synced_tables = [
        "Manga",
        "Chapter",
        "Category",
        "CategoryManga",
        "History",
        "ChapterSync",
        "Extension",
        "Repo",
    ]
    for table in synced_tables:
        cur.execute(f"PRAGMA table_info({table})")
        columns = [col[1] for col in cur.fetchall()]
        set_clauses = []
        if "dirty" in columns:
            set_clauses.append("dirty = 0")
        if "commit_id" in columns:
            set_clauses.append("commit_id = 0")
        if set_clauses:
            cur.execute(f"UPDATE {table} SET {', '.join(set_clauses)}")  # noqa: S608 (static table name and clauses)

    cur.execute("DELETE FROM SyncCommit")

    strip_account_info(cur)


def process_mark_unread(cur: sqlite3.Cursor) -> None:
    """
    Reset all chapters to unread and clear any'last read' inference state.

    Library, categories, Repos and Sources are left untouched.
    """
    cur.execute(
        """
        UPDATE Chapter
        SET read = 0,
            last_page_read = 0,
            last_read_at = 0
        """
    )
    cur.execute("PRAGMA table_info(ChapterSync)")
    if cur.fetchall():
        cur.execute(
            """
            UPDATE ChapterSync
            SET read = 0,
                last_page_read = 0,
                last_read_at = 0
            """
        )

    strip_account_info(cur)


PROCESSORS = {
    "reset": process_reset,
    "history": process_history,
    "resync": process_resync,
    "mark_unread": process_mark_unread,
}


def _contents_checksum(data: bytes) -> str:
    """
    Compute the backup's integrity checksum.

    The Tachimanga backup format pins sha1 in meta.json purely as an
    integrity check (never for security), so a stronger digest cannot be
    used without breaking the app.
    """
    return hashlib.sha1(data).hexdigest()  # noqa: S324


def process_database(db_path: Path, mode: str) -> None:
    """Run the selected mode against the extracted database file."""
    conn = sqlite3.connect(db_path)
    cur = conn.cursor()
    PROCESSORS[mode](cur)
    resync_autoincrement_sequences(cur)
    conn.commit()
    cur.execute("VACUUM")
    conn.commit()
    conn.close()


def _repack_contents(contents_dir: Path, new_contents_zip: Path) -> None:
    """Rebuild contents.zip from the modified extracted directory."""
    with zipfile.ZipFile(new_contents_zip, "w", zipfile.ZIP_DEFLATED) as archive:
        for file_path in sorted(contents_dir.rglob("*")):
            relative = file_path.relative_to(contents_dir).as_posix()
            if file_path.is_dir():
                archive.writestr(relative + "/", "")
            else:
                archive.write(file_path, relative)


def build(src_tmb: str, dst_tmb: str, mode: str) -> None:
    """Unpack a .tmb backup, process its database, and repack it."""
    if mode not in PROCESSORS:
        logger.error("Unknown mode: %s (available: %s)", mode, list(PROCESSORS))
        sys.exit(1)

    work = Path(tempfile.mkdtemp(prefix="tmb_build_"))
    try:
        with zipfile.ZipFile(src_tmb) as archive:
            archive.extractall(work)

        meta_path = work / "meta.json"
        contents_zip_path = work / "contents.zip"

        with meta_path.open(encoding="utf-8") as handle:
            meta = json.load(handle)

        contents_dir = work / "contents"
        contents_dir.mkdir(exist_ok=True)
        with zipfile.ZipFile(contents_zip_path) as archive:
            archive.extractall(contents_dir)

        process_database(contents_dir / "tachimanga.db", mode)

        new_contents_zip = work / "contents_new.zip"
        new_contents_zip.unlink(missing_ok=True)
        _repack_contents(contents_dir, new_contents_zip)

        data = new_contents_zip.read_bytes()
        # Integrity checksum only, not used for any security purpose. The
        # Tachimanga backup format pins sha1 in meta.json, so it cannot be
        # replaced by a stronger digest without breaking the app.
        new_sha1 = _contents_checksum(data)
        meta["checksum"] = new_sha1
        meta["size"] = len(data)
        meta["updateAt"] = int(time.time())

        new_meta_path = work / "meta_new.json"
        with new_meta_path.open("w", encoding="utf-8") as handle:
            json.dump(meta, handle, indent=2, ensure_ascii=False)

        Path(dst_tmb).unlink(missing_ok=True)
        with zipfile.ZipFile(dst_tmb, "w", zipfile.ZIP_DEFLATED) as archive:
            archive.write(new_meta_path, "meta.json")
            archive.write(new_contents_zip, "contents.zip")

        logger.info("Done [%s]: %s", mode, dst_tmb)
        logger.info("  contents.zip sha1 = %s", new_sha1)
        logger.info("  contents.zip size = %d", len(data))
    finally:
        shutil.rmtree(work, ignore_errors=True)


def main() -> None:
    """CLI entry point."""
    if len(sys.argv) != 4:  # noqa: PLR2004
        target = f"{Path(sys.argv[0]).name} <source.tmb> <output.tmb> <reset|history|resync|mark_unread>"
        logger.error("Usage: python3 %s", target)
        sys.exit(1)
    build(sys.argv[1], sys.argv[2], sys.argv[3])


if __name__ == "__main__":
    main()
