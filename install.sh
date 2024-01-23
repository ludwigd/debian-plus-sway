#!/bin/bash
set -eo  pipefail

# Wifi-support and basic networking tools
subtask_network () {
    apt install --assume-yes \
	bluez \
	firewalld \
	network-manager
}

# Install pipewire along with some tools
subtask_audio () {
    apt install --assume-yes \
	pavucontrol \
	pipewire-audio \
	playerctl \
	pulseaudio-utils
}

# Printing support
subtask_printing () {
    apt install --assume-yes \
	cups \
	ghostscript \
	hplip \
	libsane-hpaio \
	system-config-printer
}

# Fonts
subtask_fonts () {
    apt install --assume-yes \
	fontconfig \
	fonts-dejavu \
	fonts-font-awesome \
	fonts-jetbrains-mono \
	fonts-liberation2 \
	fonts-noto-cjk \
	fonts-noto-color-emoji
}

# Very basic desktop, just sway and vim along with audio and wifi support
task_basic_desktop () {
    subtask_network
    subtask_audio
    
    apt install --assume-yes \
	sway \
	swayidle \
	swaylock \
	vim \
	xdg-desktop-portal-gtk \
	xdg-desktop-portal-wlr \
	xwayland
}

# An enhanced desktop environment
task_enhanced_desktop () {
    task_basic_desktop
    subtask_fonts
    subtask_printing
    
    apt install --assume-yes \
	clipman \
	findutils \
	gammastep \
	i3status \
	jq \
	kanshi \
	light \
	mate-polkit \
	python3-i3ipc \
	rofi \
	wev \
	x11-utils \
	xdg-utils

    LOCAL_BIN_DIR=/usr/local/bin
    mkdir -p $LOCAL_BIN_DIR
    
    wget https://raw.githubusercontent.com/ludwigd/swaycaffeine/main/swaycaffeine -O $LOCAL_BIN_DIR/swaycaffeine
    chmod +x $LOCAL_BIN_DIR/swaycaffeine
    
    wget https://raw.githubusercontent.com/ludwigd/yaws/main/yaws -O $LOCAL_BIN_DIR/yaws
    chmod +x $LOCAL_BIN_DIR/yaws
}

# Extra desktop apps
task_apps () {
    apt install --assume-yes \
	adwaita-icon-theme \
	android-file-transfer \
	android-sdk-platform-tools \
	borgbackup \
	distrobox \
	emacs \
	fish \
	flatpak \
	git-core \
	gnome-icon-theme \
	gnome-keyring \
	gnome-themes-extra \
	htop \
	imv \
	libpam-gnome-keyring \
	lynx \
	neomutt \
	podman \
	powertop \
	ranger \
	sshfs \
	thunar \
	udiskie \
	virt-manager \
	xsane \
	zathura \
	zathura-ps

    flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
    flatpak remote-modify --enable flathub
	
    flatpak install -y flathub \
	    com.github.xournalpp.xournalpp \
	    io.github.quodlibet.QuodLibet \
	    io.mpv.Mpv \
	    org.chromium.Chromium \
	    org.gimp.GIMP \
	    org.inkscape.Inkscape \
	    org.keepassxc.KeePassXC \
	    org.libreoffice.LibreOffice \
	    org.mozilla.firefox
}

# Development Tools
task_development () {
    apt install --assume-yes \
	autoconf \
	automake \
	bc \
	binutils \
	bison \
	cargo \
	cmake \
	exuberant-ctags \
	flex \
	g++ \
	gcc \
	gdb \
	git \
	javacc \
	libglib2.0-dev \
	make \
	openjdk-17-jdk \
	openjdk-17-jre \
	patch \
	patchutils \
	python3 \
	python3-pip \
	python3-virtualenv \
	rustc \
	strace \
	zstd
}

# TeXlive and publishing
task_publishing () {
    apt install --assume-yes \
	aspell \
	aspell-de \
	aspell-en \
	hunspell \
	hunspell-de-de \
	imagemagick \
	pandoc \
	texlive-base \
	texlive-bibtex-extra \
	texlive-extra-utils \
	texlive-font-utils \
	texlive-fonts-extra \
	texlive-fonts-recommended \
	texlive-formats-extra \
	texlive-lang-english \
	texlive-lang-german \
	texlive-latex-base \
	texlive-latex-extra \
	texlive-latex-recommended \
	texlive-luatex \
	texlive-metapost \
	texlive-pictures \
	texlive-plain-generic \
	texlive-pstricks \
	texlive-publishers \
	texlive-science \
	texlive-xetex \
	texstudio \
	xfig
}

# Updates
task_update_system () {
    apt update
    apt upgrade --assume-yes
    if [[ -f "/usr/bin/flatpak" ]]; then
	flatpak -y update
    fi
}

# Dotfiles
task_dotfiles () {
    # Check dependencies
    if [[ ! $(which git) ]]; then
	exit 1
    fi
    
    # Clone the repository
    dotfiles=$HOME/.dotfiles
    git clone --bare https://github.com/ludwigd/dotfiles $dotfiles

    # Manage dotfiles the openSUSE way
    # See: https://news.opensuse.org/2020/03/27/Manage-dotfiles-with-Git/
    pushd .
    cd $HOME
    git --git-dir=$dotfiles --work-tree=$HOME checkout -f
    popd
}

usage () {
    echo "install.sh <task>"
    echo "  This script installs my Debian+Sway environment."

    echo -e "\\nAvailable tasks:"
    echo "  basic                   - just sway and vim (incl. audio and wifi support)"
    echo "  enhanced                - an enhanced environment compared to basic"
    echo "  apps                    - desktop apps"
    echo "  development             - some programming languages and tools"
    echo "  publishing              - an opinionated selection of TeXlive collections and tools"
    echo "  everything              - enhanced + apps +  development + publishing"
    echo "  update                  - install updates (dnf + flatpak)"
    echo "  dotfiles                - install dotfiles (requires enhanced + apps)"
    echo "  unattended              - update + everything + dotfiles + reboot"
}

assure_root () {
    if [ $UID -ne 0 ]; then
	echo "You must be root to install software."
	exit 1
    fi
}

main () {
    local cmd=$1

    if [[ -z "$cmd" ]]; then
	usage
    elif [[ $cmd == "basic" ]]; then
	assure_root
	task_basic_desktop
    elif [[ $cmd == "enhanced" ]]; then
	assure_root
	task_enhanced_desktop
    elif [[ $cmd == "apps" ]]; then
	assure_root
	task_apps
    elif [[ $cmd == "development" ]]; then
	assure_root
	task_development
    elif [[ $cmd == "publishing" ]]; then
	assure_root
	task_publishing
    elif [[ $cmd == "everything" ]]; then
	assure_root
	task_enhanced_desktop
	task_apps
	task_development
	task_publishing
    elif [[ $cmd == "dotfiles" ]]; then
	if [ $UID -ne 0 ]; then
	    task_dotfiles
	else
	    echo "You should NOT be root for this task."
	    exit 1
	fi
    elif [[ $cmd == "update" ]]; then
	assure_root
	task_update_system
    elif [[ $cmd == "unattended" ]]; then
	assure_root
	task_update_system
	task_enhanced_desktop
	task_apps
	task_development
	task_publishing

	# Who am I?
	ME=$(who am i | cut -f1 -d" ")

	# Add user to libvirt group
	usermod -aG libvirt $ME

	# Install dotfiles
	sudo -u $ME ./"$0" dotfiles

	# Reboot
	systemctl reboot
    else
	usage
    fi
}

main "$@"
