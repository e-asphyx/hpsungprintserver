FROM ubuntu:20.04

RUN export DEBIAN_FRONTEND=noninteractive && \
    apt-get update && \
    apt-get install -y cups libcupsimage2 wget

ARG ULD_VER=V1.00.39.12_00.15

WORKDIR /hpdriver
RUN wget https://ftp.hp.com/pub/softlib/software13/printers/CLP150/uld-hp_${ULD_VER}.tar.gz
RUN tar xzf uld-hp_${ULD_VER}.tar.gz

ENV DATA_DIR=/opt/hp/printer/share
ENV BIN_DIR=/opt/smfp-common/printer

RUN ARCH=$(uname -m) && \
    case "${ARCH}" in \
    "x86_64"|"amd64") ARCH_SUBDIR="x86_64" ;; \
    "armv8-a"|"armv8"|"arm64"|"aarch64") ARCH_SUBDIR="aarch64" ;; \
    *) echo "Unexpected architecture '${ARCH}'" ; exit 1 ;; \
    esac && \
    \
    mkdir -p ${DATA_DIR}/ppd/cms && \
    install -m644 ./uld/noarch/share/ppd/*.ppd ${DATA_DIR}/ppd && \
    install -m644 ./uld/noarch/share/ppd/cms/*.cts ${DATA_DIR}/ppd/cms && \
    \
    mkdir -p ${BIN_DIR}/lib && \
    install -m755 ./uld/${ARCH_SUBDIR}/libscmssc.so ${BIN_DIR}/lib && \
    mkdir -p ${BIN_DIR}/bin && \
    install -m755 ./uld/${ARCH_SUBDIR}/smfpnetdiscovery ${BIN_DIR}/bin && \
    install -m755 ./uld/${ARCH_SUBDIR}/rastertospl ${BIN_DIR}/bin && \
    install -m755 ./uld/${ARCH_SUBDIR}/pstosecps ${BIN_DIR}/bin && \
    \    
    ln -s ${BIN_DIR}/bin/smfpnetdiscovery /usr/lib/cups/backend && \
    ln -s ${BIN_DIR}/bin/rastertospl /usr/lib/cups/filter && \
    ln -s ${BIN_DIR}/bin/pstosecps /usr/lib/cups/filter && \
    ln -s ${DATA_DIR}/ppd /usr/share/cups/model/uld-hp && \
    ln -s ${DATA_DIR}/ppd /usr/share/ppd/uld-hp

WORKDIR /
RUN rm -fr /hpdriver

ARG USER=printer
ARG PASSWORD=printer
RUN useradd -g users -G lp,lpadmin -d /etc/cups -M -s /bin/false -p "$(openssl passwd -6 ${PASSWORD})" "${USER}"

ADD cupsd.conf /etc/cups

EXPOSE 631/tcp

CMD ["/usr/sbin/cupsd", "-f"]