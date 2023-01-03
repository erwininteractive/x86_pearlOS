FROM andrewthecoder/x86_64-cross-compiler

RUN pacman -Syyu --noconfirm

WORKDIR /root/pearlos
VOLUME /root/pearlos

    
