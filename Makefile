SRC=${wildcard *.lua}
SRC_PARAM=${SRC:%=--lua %}
MEDIA_CART=media.p8
OUT=combozard.p8

.PHONY: all

all: ${OUT}

${OUT}: ${SRC} ${MEDIA_CART}
	p8tool build \
		${SRC_PARAM} \
		--gfx media.p8 \
		--gff ${MEDIA_CART} \
		--map ${MEDIA_CART} \
		--sfx ${MEDIA_CART} \
		--music ${MEDIA_CART} \
		${OUT}
