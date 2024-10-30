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

# Desktop
task_desktop () {
    subtask_network
    subtask_audio
    subtask_fonts
    subtask_printing
    
    apt install --assume-yes \
        brightnessctl \
        clipman \
        desktop-base \
        findutils \
        fish \
        gammastep \
        git-core \
        gnome-keyring \
        i3status \
        jq \
        kanshi \
        libpam-gnome-keyring \
        mate-polkit \
        python3-i3ipc \
        rofi \
        sway \
        swayidle \
        swaylock \
        vim \
        wev \
        x11-utils \
        xdg-desktop-portal-gtk \
        xdg-desktop-portal-wlr \
        xdg-utils \
        xwayland
}

# Extra desktop apps
task_apps () {
    apt install --assume-yes \
        adwaita-icon-theme \
        android-file-transfer \
        android-sdk-platform-tools \
        borgbackup \
        chromium \
        distrobox \
        emacs \
        ffmpeg \
        firefox-esr \
        gimp \
        gnome-icon-theme \
        gnome-themes-extra \
        gvfs-backends \
        htop \
        imv \
        inkscape \
        keepassxc \
        libreoffice \
        libreoffice-gtk3 \
        lynx \
        mpv \
        neomutt \
        podman \
        powertop \
        quodlibet \
        sshfs \
        thunar \
        udiskie \
        virt-manager \
        xournalpp \
        xsane \
        zathura \
        zathura-ps
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
task_update () {
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

    # Link the default wallpaper
    ln -s /usr/share/desktop-base/active-theme/wallpaper/contents/images/1920x1080.svg $HOME/background.png
}

usage () {
    echo "install.sh <task>"
    echo "  This script installs my Debian+Sway environment."

    echo -e "\\nAvailable tasks:"
    echo "  update                  - install updates (apt + flatpak)"
    echo "  desktop                 - sway plus tools, network, audio, printing"
    echo "  apps                    - desktop apps"
    echo "  development             - some programming languages and tools"
    echo "  publishing              - an opinionated selection of TeXlive collections and tools"
    echo "  dotfiles                - install dotfiles (requires desktop)"
    echo "  everything              - all of the above + some vodoo + reboot"
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
    elif [[ $cmd == "desktop" ]]; then
        assure_root
        task_desktop
    elif [[ $cmd == "apps" ]]; then
        assure_root
        task_apps
    elif [[ $cmd == "development" ]]; then
        assure_root
        task_development
    elif [[ $cmd == "publishing" ]]; then
        assure_root
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
        task_update
    elif [[ $cmd == "everything" ]]; then
        assure_root
        task_update
        task_desktop
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
