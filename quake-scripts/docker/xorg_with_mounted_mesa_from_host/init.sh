cd /build/mesa && \
	git clean -qfdx && \
	meson setup builddir/ -Dgallium-drivers=radeonsi -Dvulkan-drivers= -Dplatforms=x11 -Degl=false && \
	meson compile -C builddir/ && \
	meson devenv -C builddir xinit /home/quakeuser/quake/ezQuake-x86_64.AppImage +playdemo fps3 -- :666
