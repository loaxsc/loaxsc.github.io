Title: 優化 PDF 的檔案體積
Date: 2018-12-09
Category: article

# 優化 PDF 的檔案體積

## 為什麼想要研究這個問題
之前重新調整過頁面的排版後發現檔案的體積變大了，而且仔細看一下，可以發現有些頁面，文字變得比較模糊。重新檢查一下自己處理的步驟，原來是用 CEP 取內容時勾選了 deskew ，圖片的格式跑掉了。我想了一下，乾脆探索一下怎麼優化檔案體積，找出在盡可能保持頁面的視覺品質下縮減檔案體積的方法。

如果是PNG格式的圖片，那影響檔案體積最重要的參數就是顏色的數量，先分析了一下原始檔，看看原製作者用的是怎麼樣校調的：

![原始檔使用的顏色數]({static}/img/026.png)

還真奇怪，因為畫面看起來不像是顏色豐富的感覺，我猜可能是浮水印的關係，把浮水印移除後再重新分析一次

![移除浮水印後，純文字部分使用的顏色數]({static}/img/027.png)

所以，原製作者他最終是把頁面處理成15色的圖檔，只是因為後來打上浮水印的關係使顏色數暴增，不過因為浮水印只佔一小區塊，所以即使顏色數變得混亂，檔案的體積倒是增加的不大。

如果想進一步縮減檔案的體積，我想到兩個途徑，一個是把每頁文字的部分再進一部轉成 4 色而圖片保持 15 色；另一個途徑是把整張圖片轉成黑白的。

## 方法一：文字４色，插圖１５色
先把原始檔中有插圖的頁面找出來，將插圖的位置、大小資訊記錄在 page_with_pic.info 中，然後把插圖和文字分開。

將文字和插圖分開的 bash script

    test -d crop-pic || mkdir crop-pic
    while read line; do
        base=${line%,*}.png
        geo=${line#*,}
        pic=crop-pic/${line%,*}_${line#*,}.png

        echo "processing $base"

        # crop-pic
        convert $base -write mpr:src \
            -crop $geo +repage -write $pic +delete \
            mpr:src -region $geo -fill white -colorize 100 $base

    done < page_with_pic.info

要對文字做減色前先做顏色樣本 gray4.png

    convert xc:'rgb(0,0,0)' xc:'rgb(85,85,85)' \
            xc:'rgb(170,170,170)' xc:'rgb(255,255,255)' \
            +append gray4.png

然後將只有文字的圖片減成四色

    test -d colors || mkdir colors
    ls page-???.png | xargs -I _IMG_ convert _IMG_ \
        -print 'processing %f\n' +dither -remap gray4.png \
        png8:_IMG_

最後把插圖合併回來

    while read line; do
        base=${line%,*}.png
        geo=${line#*,}
        pic=crop-pic/${line%,*}_${line#*,}.png

        convert $base $pic \
            -geometry $geo -compose over -composite png8:$base
    done < page_with_pic.info

利用 optipng 優化 png 的編碼

    optipng page-???.png

最後利用 FreePic2Pdf 將圖檔合併成 PDF，新檔案和原始檔畫面並沒有差很多

![新檔案和原始檔畫面並沒有差很多]({static}/img/029.png)

不過檔案體積下降了不少

![不過檔案體積下降了不少]({static}/img/030.png)


## 黑白圖檔
另一個途徑是將頁面轉成黑白雙色。

用黑白圖片來做電子書也可以取得很好的效果，但前提是圖片的解析度要夠大。如果原始檔解析度不夠高，那利用放大、模糊、銳化三個步驟處理圖片，處理後雖然可能文字會有點變形，但是依舊能取得很好的效果。

原始的圖檔解析度不是很大，如果直接轉黑白圖片效果會很糟，先將圖片放大３倍

    mogrify -print 'processing %f\n' -resize 300% page-???.png

要用黑白圖檔做 PDF 電子書，視覺效果要好，插圖和文字必須分開處理，還是老樣子，把插圖的位置和大小資訊記錄在 page_with_pic.info ，然後將插圖和文字分開來。

    test -d crop-pic || mkdir crop-pic
    while read line; do
        base=${line%,*}.png
        geo=${line#*,}
        pic=crop-pic/${line%,*}_${line#*,}.png

        echo "processing $base"

        # crop-pic
        convert $base -write mpr:src \
            -crop $geo +repage -write $pic +delete \
            mpr:src -region $geo -fill white -colorize 100 $base

    done < page_with_pic.info

##轉換文字
我在轉換文字部分的圖檔都是利用 CEP，因為 CEP 裡面有一個 wolf 演算法，在轉換時稍微調整一下 wolf 演算法的參數，那轉換出來的效果明顯好過用其它的工具，尤其是圖片的亮度分佈不均勻時，差別非常大。

將圖片放大後，在將圖片轉成黑白時有一種叫偽高清的方法，就是先將圖片模糊後再強力銳化，利用強力銳化時產生的邊緣效果將文字邊緣切割出來，雖然文字會有些變形，但是邊緣非常清淅。

![wolf vs 原始圖檔 vs 偽高清]({static}/img/032.png)

看個人喜好，我是比較偏好單純用 wolf 轉出來的效果。

##轉換圖片
將插圖轉成黑白圖片時要採用 dither 的方式，dither 會用不同密度的點來代替灰階，如果沒經過這道手續直接轉黑白兩色，出來的結果圖片中的內容到底是什麼根本難以辨視。Imagemagick 中可選用的 dither 的方法有 Riemersma 和 FloydSteinberg 兩種，我是偏好 Floydsteinberg

    ls *.png | xargs -I _IMG_ \
        convert _IMG_ -dither floydsteinberg -remap pattern:gray50 _IMG_

![Riemersma vs 原始圖檔 vs Floydsteinberg ]({static}/img/033.png)

將插圖合併回來

    while read line; do
        base=${line%,*}.png
        geo=${line#*,}
        pic=crop-pic/${line%,*}_${line#*,}.png

        convert $base $pic \
            -geometry $geo -compose over -composite png8:$base
    done < page_with_pic.info

直接用 FreePic2Pdf 將圖片合併成 PDF，FreePic2Pdf 對 BiLevel 的圖檔有作優化，採用 JBig2 算法，合併出來的檔案體積會進一步壓縮。

勾選 FreePic2Pdf JBig2 算法

![勾選 FreePic2Pdf JBig2 算法]({static}/img/034.png)

原始檔 vs Bilevel的效果比較

![原始檔 vs Bilevel的效果比較]({static}/img/035.png)

檔案體積的比較

![檔案體積的比較]({static}/img/036.png)
