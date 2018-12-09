Title: 移除浮水印的方法
Date: 2018-12-09
Category: article

# 移除 watermark

常常在讀電子書時見到頁面中有浮水印，在沒接觸 Imagemagick 前，只會移除那種淡淡的、單色，只要簡單地提高對比度或亮度就可以移除的浮水印

![簡單的浮水印]({static}/img/021.png)

如果說遇到比較複雜的圖案，就只能默默的接受。在研究使用 Imagemagick 時意外發現兩種移除浮水印的方法，相對簡單的調整對比和亮度而言，可以說是移除的非常漂亮。 第一種方法針對的是在固定位置的浮水印，如果你可以找到用來做浮水印的原始圖片，那固定位置的浮水印是可以漂亮的移除的。第二種方法針對的是彩色的浮水印。電子書內的圖片因為主要的內容是黑白的文字，所以如果遇到彩色的浮水印，知道方法的話也是有辨法移除的。

## 移除固定位置的浮水印

移除固定位置浮水印的原理是這樣的，先找到原始做為浮水印的圖案，這很容易，因為電子書中有些浮水印會打在空白處，找到該處把浮水印擷取下即可取得浮水印的原始圖案。擷取時記得把擷取的位置和尺寸記下來，然後就可以編寫 Imagemagick 的指令下去批次把浮水印移除掉。

拿《數學之美》第一章為例，這本電子書的浮水印在固定位置，而且不是簡單的單色、淡色，無法在不破壞文字的前提下靠調整對比、亮度或曲線來移除它。

![數學之美的浮水印，雖然位置固定，但是圖案的結構複雜]({static}/img/016.png)

我們先找到空白處的浮水印，擷取並記錄 geometry 資訊。我是用 gimp 來做這個步驟，因為用滑鼠大致選取好範圍後，可以利用方向鍵對選取方塊進行微調選取的尺寸及位置，非常方便

![gimp 可以用方向鍵微調選取方塊]({static}/img/022.png)

微調完一切就緒後，因為 gimp 導出選取區域至檔案的操作太鎖碎了，我是直接複製到剪貼簿，再利用下面的指令把浮水印導出到檔案

    xclip -selection clipboard -t image/png -o > wmark.png

記得要把 geometry 資訊記錄下來，在視窗的左下角的工具選項中可以找到資訊。注意，gimp 的版面中上面是偏移位置，下面是寬度長度，我一開始沒注意到，導致後面的一直不對…

![gimp 中找到 geometry 資訊]({static}/img/023.png)

其實可以不用在 gimp 介面中找資訊再慢慢打，我在網上搜到將選取方塊的 geometry 資訊複製到剪貼簿的 [python-fu 腳本](copy-selection-coordinates.py)，將這個腳本丟到 gimp plugin 資料夾中後，這個腳本會在選單中增加一個項目，再到 gimp 的設定中為該選單項目指定一個熱鍵即可。

![gimp選單項目]({static}/img/024.png)

在批次移除前先檢查一下頁面圖片的尺寸是否全部一致，打上浮水印的製作者可能不希望別人輕易就把浮水印移除，所以會故意把圖片的尺寸調整的不一致

    identify page-???.* | cut -d ' ' -f 1,3 | \
        sort -n -k 2 | vim -R -c "set nu | nmap q :q<cr>" -

![檢查圖片尺寸]({static}/img/020.png)

數學之美第一章圖片的尺寸相當一致。

我們以下面的指令移除打在頁面上的浮水印

    # 移除浮水印的 Code
    ls page-???.png | xargs -I _IMG_ \
    convert _IMG_ -write mpr:src \
        -crop 291x363+691+1081 +repage -write mpr:src_s \
        wmark.png -compose difference -composite -threshold 0 -write mpr:mask +delete \
        mpr:src_s -mask mpr:mask -fill white +opaque white +mask -level 0%,100%,0.7 -write mpr:src_s +delete \
        mpr:src mpr:src_s -geometry +691+1081 -compose over -composite \
        ../01wmark/_IMG_

解釋一下上面的指令做了什麼：將頁面上對應的區塊和浮水印相減，這樣浮水印就被去掉了。可是這種方法會破壞被浮水印覆蓋的文字，所以需要再做進一步的處理。將去掉浮水印的圖案做成遮罩，

![浮水印消失啦！]({static}/img/025.png)

## 移除彩色的浮水印
有些電子書上會打上彩色的浮水印，移除的原理其也不難，就抓住一個要點：電子書上的文字通常都是灰階的，因此構成文字的像素 RGB 值差距不大，通常在正負10(0 ~ 255)內，否則肉眼就會察覺出彩度來，這樣只要去檢查頁面中像素 RGB 之間的差值，太大的就替代成白色，就可以把浮水印移除掉了。

![一個彩水浮水印的例子]({static}/img/017.png)

ImageMagick 移除浮水印的指令

    convert wmark.png -fx 'p.r > 0.692 && abs(p.r - p.b) > 0.0392 ? white : p' \
        wmark.png \

![移除浮水印後的圖案]({static}/img/018.png)

這種方法來移除浮水印會留下很多雜點，還需要進一步的處理

    convert wmark.png -write mpr:pic -threshold 75% \
        -define connected-components:area-threshold=6 \
        -connected-components 4 -threshold 0 -write mpr:mask +delete \
        mpr:pic -mask mpr:mask -fill white +opaque white wmark.png

![進一步處理後的圖案]({static}/img/019.png)

很漂亮的移除了
