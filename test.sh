(venv) [root@Server ~/self-supervised-learning]# cd /root/self-supervised-learning && mkdir -p data/raw logs checkpoints config && source /root/venv/bin/activate && python train.py
2024-11-01 00:29:11,212 - INFO - Initial memory usage: 452.43 MB
2024-11-01 00:29:11,213 - INFO - Starting data collection...
2024-11-01 00:29:11,215 - INFO - Found 2 Python files
2024-11-01 00:29:11,215 - INFO - Skipped 0 files due to errors or size limits
2024-11-01 00:29:11,215 - INFO - Collected 4 code-comment pairs
2024-11-01 00:29:11,216 - INFO - Successfully collected 4 code-comment pairs
2024-11-01 00:29:12,835 - INFO - Using device: cpu
2024-11-01 00:29:13,308 - INFO - Memory usage before epoch 1: 485.39 MB
2024-11-01 00:29:36,442 - INFO - Epoch 1/20, Train Loss: 0.4016, Val Loss: 0.0000

=== Training Progress ===
Epoch 1/20, Train Loss: 0.4016, Val Loss: 0.0000
2024-11-01 00:29:38,123 - INFO - Saved best model to checkpoints/20241101_002913/model_epoch01_loss0.0000.pt

=== Training Progress ===
Saved best model to checkpoints/20241101_002913/model_epoch01_loss0.0000.pt
2024-11-01 00:29:38,123 - INFO - Memory usage before epoch 2: 2097.71 MB
2024-11-01 00:30:03,511 - INFO - Epoch 2/20, Train Loss: 0.3727, Val Loss: 0.0000

=== Training Progress ===
Epoch 2/20, Train Loss: 0.3727, Val Loss: 0.0000
2024-11-01 00:30:03,512 - INFO - EarlyStopping counter: 1 out of 5
2024-11-01 00:30:03,512 - INFO - Memory usage before epoch 3: 2090.53 MB
2024-11-01 00:30:32,419 - INFO - Epoch 3/20, Train Loss: 0.3159, Val Loss: 0.0000

=== Training Progress ===
Epoch 3/20, Train Loss: 0.3159, Val Loss: 0.0000
2024-11-01 00:30:32,419 - INFO - EarlyStopping counter: 2 out of 5
2024-11-01 00:30:32,419 - INFO - Memory usage before epoch 4: 2090.56 MB
^C2024-11-01 00:30:34,073 - INFO - 
Force exiting...
2024-11-01 00:30:36,570 - INFO - Training report generated at: reports/training_report_20241101_003034

=== Training Report ===
Training report generated at: reports/training_report_20241101_003034
2024-11-01 00:30:36,571 - INFO - Generated training report

=== Training Report ===
Generated training report