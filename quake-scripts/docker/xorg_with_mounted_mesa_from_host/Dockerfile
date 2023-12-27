FROM debian:testing
RUN bash -c "sed -i 's/deb$/deb deb-src/g' /etc/apt/sources.list.d/*"
RUN apt update && \
    apt build-dep -y mesa && \
    apt install -y \
    git \
    xserver-xorg xserver-xorg-legacy x11-xserver-utils \
    xinit \
    fuse \
    `#mesa-utils libglx0 libglx-mesa0 libgl1-mesa-dri` \
    xterm \
    && rm -rf /var/lib/apt/lists/* && \
    useradd -m -u 1000 -s /bin/bash quakeuser
RUN usermod -a -G video,tty,audio,input,root,render,plugdev quakeuser

RUN bash -c 'echo -e "allowed_users = anybody\nneeds_root_rights = yes" > /etc/X11/Xwrapper.config'

#run if we need to override driver order
RUN mkdir -p /etc/X11/xorg.conf.d
RUN bash -c 'echo -e "Section \"Module\"\nLoad \"modesetting\"\nLoad \"amdgpu\"\nEndSection" > /etc/X11/xorg.conf.d/01-modesetting.conf'

COPY init.sh /init.sh
RUN chmod +x /init.sh
#build mesa
RUN mkdir -p /build
RUN chmod 1777 /build

USER quakeuser
WORKDIR /home/quakeuser

CMD /init.sh
