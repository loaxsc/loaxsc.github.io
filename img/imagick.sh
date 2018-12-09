# vim: expandtab fdm=marker
convert Arror_right.gif -rotate 180 Arror_left.gif

convert Arror_left.gif -gravity east -chop 3x0 -write mpr:left +delete \
        Arror_right.gif -gravity west -chop 3x0 mpr:left +swap +append \
        Arror_2Side.gif


convert 007.png -bordercolor black -border 1x1 \
    -background pink -splice 10x0 \
    -bordercolor pink -border 0x25 \
    -gravity center -size 100x352 -background khaki \
        -font Noto-Sans-CJK-TC-Regular -pointsize 12 label:筆記 \
        +append 008.png

convert wmark.src.png -gravity center -background khaki \
    -font Noto-Sans-CJK-TC-Regular -pointsize 12 label:浮水印原始圖案 \
    -append wmark.src.c.png

convert wmark.a.png -gravity center -background khaki \
    -font Noto-Sans-CJK-TC-Regular -pointsize 12 label:固定位置的浮水印 \
    -append wmark.a.c.png

convert wmark.src.c.png ../Arror_2Side.gif wmark.a.c.png \
    -background none -gravity center +append wmark.result.png
