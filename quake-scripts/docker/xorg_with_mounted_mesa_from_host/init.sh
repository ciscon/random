cd /build/mesa && \
	git clean -qfdx && \
	meson setup --reconfigure builddir/ -Dgallium-drivers=radeonsi -Dvulkan-drivers= -Dplatforms=x11 && \
	meson compile -C builddir/ && \
	meson devenv -C builddir xinit /home/quakeuser/quake/ezQuake-x86_64.AppImage -- :666
