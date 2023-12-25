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

#build mesa
RUN mkdir -p /build
WORKDIR /build

#good ARG MESA_VER=c21ce0401458417287e9419abb09ac945c588e65
#bad ARG MESA_VER=1e4b5390425c13b493b05bdaf17a94a6f2f32057

ARG MESA_VER=1e4b5390425c13b493b05bdaf17a94a6f2f32057

RUN cd mesa && git checkout $MESA_VER && \
  meson setup --reconfigure builddir/ -Dgallium-drivers=radeonsi -Dvulkan-drivers= -Dplatforms=x11 && \
  meson install -C builddir/

USER quakeuser
WORKDIR /home/quakeuser
ENV LD_LIBRARY_PATH=/usr/local/lib/x86_64-linux-gnu
CMD xinit /home/quakeuser/quake/ezQuake-x86_64.AppImage -- :666
