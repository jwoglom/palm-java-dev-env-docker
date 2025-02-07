FROM ubuntu:20.04

# Setup locale:
RUN apt-get update && \
    apt-get install -y locales && \
    localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8
ENV LANG en_US.utf8

# Configure system:
RUN useradd -m -s /bin/bash devel && \
    mkdir /home/devel/dev_env && \
    chown devel:devel /home/devel/dev_env/
RUN echo "Europe/Moscow" > /etc/timezone && \
    ln -sf /usr/share/zoneinfo/Europe/Moscow /etc/localtime
ENV TZ=Europe/Moscow

################################################################################

# Install supplementary packages:
RUN apt-get install -y dosfstools \
                       git \
                       build-essential \
                       libsdl2-dev \
                       vim \
                       x11-xserver-utils \
                       xorg-dev \
                       wget \
                       libgl1-mesa-glx \
                       libgl1-mesa-dri \
                       xterm

#
# Install JDK6 and WTK:
#
RUN apt-get install -y ed \
                       g++-multilib \
                       gcc-multilib
ENV JDK=jdk-1_5_0_22-linux-i586.bin
ENV WTK=sun_java_wireless_toolkit-2.5.2_01-linuxi486.bin
COPY ./$JDK ./$WTK ./scripts/hack-jdk-installer.sh ./scripts/hack-wtk-installer.sh /usr/
# Install JDK 1.5:
RUN chmod u+x /usr/$JDK /usr/hack-jdk-installer.sh && \
    /usr/hack-jdk-installer.sh /usr/$JDK && \
    cd /usr && /usr/$JDK && \
    echo 'PATH=$PATH:/usr/jdk1.5.0_22/bin' >> /home/devel/.bashrc && \
    echo 'PATH=$PATH:/usr/jdk1.5.0_22/bin' >> /root/.bashrc
# Install WTK 2.5.2_01:
ENV PATH="${PATH}:/usr/jdk1.5.0_22/bin"
RUN chmod u+x /usr/$WTK /usr/hack-wtk-installer.sh && \
    /usr/hack-wtk-installer.sh /usr/$WTK && \
    cd /usr && /usr/$WTK && \
    mv /usr/0 /usr/WTK2.5.2 && \
    echo 'export PATH=$PATH:/usr/WTK2.5.2/bin' >> /home/devel/.bashrc && \
    echo 'export MIDP_HOME=/usr/WTK2.5.2' >> /home/devel/.bashrc && \
    echo 'export J2MEWTK_HOME=/usr/WTK2.5.2' >> /home/devel/.bashrc && \
    echo 'export MIDPAPI=$J2MEWTK_HOME/lib/midpapi20.jar' >> /home/devel/.bashrc && \
    echo 'export J2MECLASSPATH=$J2MEWTK_HOME/wtklib/kenv.zip:$J2MEWTK_HOME/wtklib/kvem.jar:$J2MEWTK_HOME/wtklib/lime.jar:$J2MEWTK_HOME/lib/cldcapi10.jar' >> /home/devel/.bashrc

# Install additional libraries for WTK:
RUN dpkg --add-architecture i386 && \
    apt-get update && \
    apt-get install -y libxext6:i386 libxt6:i386
# Install jar2prc:
RUN apt-get install -y wine32 && \
    mkdir /home/devel/jar2prc && \
    echo "alias jar2prc='wine /home/devel/jar2prc/bin/jartoprc.exe'" >> /home/devel/.bashrc
VOLUME /home/devel/jar2prc
# Install Eclipse Pulsar:
RUN apt install -y libgtk2.0-0:i386 libxtst6:i386 && \
    wget -O pulsar.tar.gz -c https://www.eclipse.org/downloads/download.php?file=/technology/epp/downloads/release/helios/SR1/eclipse-pulsar-helios-SR1-linux-gtk.tar.gz && \
#   wget -O pulsar.tar.gz -c https://www.eclipse.org/downloads/download.php?file=/technology/epp/downloads/release/helios/SR1/eclipse-pulsar-helios-SR1-linux-gtk-x86_64.tar.gz && \
    tar zxvf ./pulsar.tar.gz -C /home/devel && \
    rm -f ./pulsar.tar.gz && \
    chown -R devel:devel /home/devel/eclipse && \
    echo "alias eclipse='/home/devel/eclipse/eclipse'" >> /home/devel/.bashrc
# Setup root password:
RUN sed -ri 's/root:\*:(.*)/root::\1/g' /etc/shadow

################################################################################

USER devel

# Install uARM:
WORKDIR /home/devel/dev_env
RUN git clone https://github.com/uARM-Palm/uARM.git 2>&1 && \
    cd uARM && \
    chmod a-x *.c *.h Makefile && \
    sed -ri -e 's/(^DEVICE\t+\+=.+)/#\1/g' \
            -e 's/^#(DEVICE\t+\+= .+TungstenE2.+)/\1/g' Makefile && \
    make && \
    echo 'PATH+=$PATH:/home/devel/dev_env/uARM' >> ~/.bashrc && \
    echo "export LIBGL_ALWAYS_INDIRECT=1" >> ~/.bashrc && \
    echo "export LIBGL_ALWAYS_SOFTWARE=true" >> ~/.bashrc && \
    echo "alias emulator='uARM -r /home/devel/os_images/Palm-Tungsten-E2-nor.bin -n /home/devel/os_images/Palm-Tungsten-E2-nand.bin -s /home/devel/sdcard.bin'" >> ~/.bashrc
# Download images for Palm Tungsten E2:
WORKDIR /home/devel
RUN mkdir os_images && \
    cd os_images && \
    wget -c https://palmdb.net/content/files/archive-rom/palm-roms-complete/Palm-Tungsten-E2-nand.bin \
            https://palmdb.net/content/files/archive-rom/palm-roms-complete/Palm-Tungsten-E2-nor.bin 2>&1

################################################################################

# Fixes for Java GUI to render it properly:
RUN echo "export _JAVA_OPTIONS='-Dawt.useSystemAAFontSettings=lcd -Dswing.defaultlaf=com.sun.java.swing.plaf.gtk.GTKLookAndFeel'" >> ~/.bashrc && \
    echo "export GDK_SCALE=2" >> ~/.bashrc && \
    echo "export GDK_DPI_SCALE=0.5" >> ~/.bashrc
# Create directory for sources:
RUN mkdir sources sdcard j2mewtk
# Save next catalogs between container restarts:
VOLUME /home/devel/sources
VOLUME /home/devel/sdcard
VOLUME /home/devel/j2mewtk
VOLUME /home/devel/workspace

# Clear:
USER root
RUN rm -rf /var/lib/apt/lists/*

USER devel
WORKDIR /home/devel
CMD ["/bin/tail", "-f", "/dev/null"]
