FROM debian:testing
RUN apt update ; apt install -y \
    xserver-xorg xserver-xorg-legacy x11-xserver-utils \
    mesa-utils xinit \
    libglx0 libglx-mesa0 fuse `#libgl1-mesa-glx` libgl1-mesa-dri xterm \
    && rm -rf /var/lib/apt/lists/* && \
    useradd -m -u 1000 -s /bin/bash quakeuser
RUN usermod -a -G video,tty,audio,input,root,render,plugdev quakeuser

RUN bash -c 'echo -e "allowed_users = anybody\nneeds_root_rights = yes" > /etc/X11/Xwrapper.config'

#run if we need to override driver order
RUN mkdir -p /etc/X11/xorg.conf.d
RUN bash -c 'echo -e "Section \"Module\"\nLoad \"modesetting\"\nLoad \"amdgpu\"\nEndSection" > /etc/X11/xorg.conf.d/01-modesetting.conf'

USER quakeuser
WORKDIR /home/quakeuser

CMD xinit /home/quakeuser/quake/ezQuake-x86_64.AppImage -- :666
