if command -v dnf &>/dev/null || command -v yum &>/dev/null; then
	sed -i '/^PS1=/d' ~/.bashrc
	echo 'PS1="\[\033[1;32m\][\u@\h:\[\033[1;34m\]\w\[\033[1;32m\]]\[\033[0m\]# "' >> ~/.bashrc
	source ~/.bashrc
else
	sed -i '/^PS1=/d' ~/.profile
	echo 'PS1="\[\033[1;32m\][\u@\h:\[\033[1;34m\]\w\[\033[1;32m\]]\[\033[0m\]# "' >> ~/.profile
	source ~/.profile
fi
