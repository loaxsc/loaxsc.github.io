Title: 製作電子書的流程
Date: 2018-12-09
Category: article

# Title

## 現實

我一直是有閱讀電子書的習慣，讀久了就會開始覺得有些電子書的排版和自己的閱讀習慣不是很合拍，譬如：

![內容不連貫的電子書]({static}/img/002.png)

這本書的頁面算是處理得非常好的，大部分的人閱讀起來應該不會有什麼怨言，可是我會希望自己在閱讀時能全神貫注在理解內容上，不希望自己的注意力被分散出去，可是注意到頁面中的內容是不連貫的，那種不連貫就讓我感到很不順眼。這種不連貫雖然很細微，但是會增加人在閱讀時負擔，當你全神貫注在理解內容時，你還必須耗費額外的心力來調整自己視線往返的範圍，而且因為我在做筆記時習慣直接把字打在頁面空白處，這種不一致的排版有時候會找不到地方放筆記，悶啊。

我原本是用 CEP 來解決這個問題的，CEP就是 ComicEnhancer Pro，原本是作者寫來處理漫畫頁面的，經過時間的演進，慢慢變成很適合處理電子書版面的問題。經過一翻嘗試後我大致上是把版面安排成這樣

![用 CEP 修正過的版面]({static}/img/004.png)

這樣子的話內容是連貫下來的，而且右邊預留了足夠的空間可以做筆記

大部分的時候我都很滿意這樣的效果，但還是會碰到一些解決不了的情況，譬如說有些書是有註解的，有註解也就算了，排版還分左右頁，左右頁的註解還不同邊

![註解在左右邊界的電子書]({static}/img/005.png)

還有時會遇到內容只有一點點，整個頁面留了一片空白

![留有大段空白的頁面]({static}/img/003.png)

你會覺得那不是必要的，可是用 CEP 並不好處理，雖然不是不能處理，但要採取非常多步驟，非常費工。CEP 是圖形介面的軟體，它有些功能藏在介面的深處，當你需要用到時，常常讓人覺得我只是要做個小處理，怎麼要按那麼多次滑鼠，做那麼多操作？

還有些時候需要利用 CEP 對圖片進行優化時，CEP 是沒有辨法讓你調整處理的順序，如果你想採取的步驟和它預設的不同，你就得分次做…這讓人超悶的。

後來注意到 Imagemagick ，想說試一下 Imagemagick，我原本只是用來切切邊界、縮放圖片而已，一時好奇就研究一下，發現我需要的功能它大部分都可以實現，乾脆花時間把自己的需要把功能都校調出來，往後要處理 PDF 的問題時就輕鬆了。

## 期待

大概總結一下自己閱讀時對版面的期待如下：

- 希望內文是連貫的
- 希望內容要維持密度，不要一段內容結束了，還要捲動一大段才接下一段內容
- 左右邊有註解的話，註解在左邊
- 希望右邊有空白可以做筆記

## 解決方案

以吳軍的《數學之美》第一章做為素材進行實驗

### 將圖片從 PDF 檔中取出

先利用 pdfimages 把圖片解出來

    :::bash
    test -d 00src || mkdir 00src
    pdfimages -f 28 -l 41 -png -j -p 數學之美.pdf 00src/page


pdfimages 從 PDF 中解出圖片時會在檔名尾端加入編號，這樣會造成接下來寫腳本操作時不方便，先移除尾端編號

    :::bash
    for _IMG_ in page-???.* ; do mv $_IMG_ ${_IMG_:0:8}${_IMG_:12}; done

有浮水印，[拿掉它](rm_wmark.html)

### 將內容從圖片中取出

先用 CEP 把內容取出來，CEP 在取頁面內容這部分的能力是非常強悍的，在取內容時會遇到的問題譬如頁面有黑邊，頁面中有暗點，還有彩圖取內容的問題，CEP 都一一克服了，讓你基本上只要稍微設一下邊界，勾幾個選項，剩下的就交給 CEP 自動處理即可。頁碼沒什麼用，而且會增加接下來排版時的複雜度，在這邊設定手動邊界去掉它。

![用 CEP 取內容]({static}/img/013.png)

因為 CEP 切邊時擔心切到內容，因此會做邊緣補償，內容的四周會有多餘的白邊，先切掉白邊免得影響我們接下來的操作。

    mogrify -print "processing %f" -trim +repage page-???.png

### 將圖片分類

把內容取出來後因為接下來調整版面的操作不一樣，要先圖片分類，基本上分三類：

1. 只有內容的頁面
1. 有左邊註解的頁面
1. 有右邊註解的頁面。

我想偷懶，不太想自己人工分類，觀察一下圖片發現其實是可以依據一些特徵用腳本自動分類的。首先只有內容的圖片的寬度會明顯比有註解的頁面小，再來左邊註解的頁面檔案的編號固定是奇數，而右邊註解的頁面編號固定是偶數，依據這些就可以寫腳本來自動分類。

下面的指令依據圖片的寬度排序列出圖片的資訊，。

    :::bash
    identify page-???.* | cut -d ' ' -f 1,3 | \
        sort -n -k 2 | vim -R -c "set nu | nmap q :q <cr>" -

![列出圖片寬度]({static}/img/006.png)

可以發現說寬度一下子由 684 跳到 833 ，因此大致估算內容的 width 為 700 px。用下面的指令自動把符合條件的圖片移到 mid 資料夾

    :::bash
    test -d mid || mkdir mid
    identify page-???.* | cut -f 1,3 -d ' ' | cut -f 1 -d 'x' | \
    while read line; do
        pic=${line:0:12}
        width=${line#* }
        if [ $width -le 700 ] ;then
            mv $pic mid
        fi
    done

處理完單純只有內容的頁面後，再利用下面的指令來幫我們自動將有右註解的頁面分到 RP，有左註解的頁面分到 LP：

    :::bash
    test -d RP || mkdir RP
    mv page-*{2,4,6,8,0}.png RP 2> /dev/null

    test -d LP || mkdir LP
    mv page-*{1,3,5,7,9}.png LP 2> /dev/null


用指令大致將檔案分類後，先用看圖軟體檢查一下看看有沒有錯誤再繼續進行下去。

### 重新配置內容版面

接下來我們要把版面整理好，像這樣固定將註解配置在左邊。

![內容版面樣版]({static}/img/007.png)

剛剛利用圖片寬度排序時從 684 直接跳 833，這樣的話大致可以推算註解欄的寬度是 150px，不過因為註解與內文之間還有空白間隔，因此取 140px，利用下面指令抓 5 張圖檢查一下

    :::bash
    # 檢查 LP 圖片
    ls page-???.* | sed 5q | convert @- -extent 140 x:

    # 檢查 RP 圖片
    ls page-???.* | sed 5q | convert @- -gravity east -extent 140 x:

#### 排版 RP

檢查好沒問題後，先處理右頁，把註解調整到左邊。

在調整前要先思考一下要將版面調整成什麼樣。剛剛我們設定了內文的寬度是 700，註解部分的內容寬度一定小於140，那就設定成 150，和內文之間留一段空白。

用下面的指令自動將右邊的註解調到左邊，並重新排版。

    :::bash
    test -d RP/result || mkdir RP/result
    ls RP | grep .png$ | xargs -I _IMG_ \
    convert RP/_IMG_  -print "processing RP/%f\\n" -write mpr:org_pic \
            -gravity east -chop 140x0 \
            -gravity west -background black -splice 1x0 -background white -splice 1x0 -trim -chop 1x0 +repage \
            -gravity center -extent 700 -write mpr:content +delete \
        mpr:org_pic \
            -gravity east -extent 140 \
                          -background black -splice 1x0 -background white -splice 1x0 -trim -chop 1x0 +repage \
            -gravity west -extent 150 \
        mpr:content +append \
        RP/result/_IMG_

#### 排版 LP

重後排版註解在左邊的頁面

    :::bash
    test -d LP/result || mkdir LP/result
    ls LP | grep .png$ | xargs -I _IMG_ \
    convert LP/_IMG_  -print "processing LP/%f\\n" -write mpr:org_pic \
            -gravity west -chop 140x0 \
            -gravity east -background black -splice 1x0 -background white -splice 1x0 -trim -chop 1x0 +repage \
            -gravity center -extent 700 -write mpr:content +delete \
        mpr:org_pic \
            -gravity west -extent 140 \
                          -background black -splice 1x0 -background white -splice 1x0 -trim -chop 1x0 +repage \
                          -extent 150 \
        mpr:content +append \
        LP/result/_IMG_

#### 排版 MID

只有內文的頁面也需要重新排版

    :::bash
    test -d mid/result || mkdir mid/result
    ls mid | grep .png$ | xargs -I _IMG_ \
        convert mid/_IMG_ -print "processing mid/%f\\n" \
        -background white -gravity center -extent 700 \
        -gravity east -extent 850 mid/result/_IMG_

### 配置頁面

將處理完的圖片集中到 _result 資料夾

    :::bash
    test -d _result || mkdir _result
    mv ?P/result/page-???.* mid/result/page-???.* _result
    rmdir ?P/result mid/result

接下來要為內容加上四周的邊框，示意圖如下：

![為內容加上邊框]({static}/img/008.png)

右邊橙色的部分是故意留下來的空白好做筆記，筆記的寬度設定成主文寬度的 2/5 ，280px

    :::bash
    ls _result/page-???.* | xargs -I _IMG_ \
    mogrify -print "processing %f\\n" -bordercolor white -border 0x80 \
        -background white -gravity west -splice 20x0 -gravity east -splice 280x0 \
        _IMG_

### 壓縮檔案體積

版面配置好後，利用 optipng 對 png 進行編碼最佳化，壓縮檔案的體積

    :::bash
    optipng _result/page-???.*

![利用 optipng 縮小檔案體積]({static}/img/009.png)

### 合併圖片為 PDF

用 FreePic2pdf 將圖片合併成 PDF 檔

![合併圖片為PDF]({static}/img/010.png)

最後完成的結果

1. 內容是連貫的，沒有左右偏移，而且不會有大段的空白
1. 註解統一放在左邊
1. 右方留有足夠的空白可做筆記

![成果]({static}/img/011.png)

## 忍不住做的實驗

在嘗試怎麼用 ImageMagick 調整版面時想到，可不可以直接將分割的圖片串成一個連貫的長圖，這樣不就可以把連貫性做到極緻嗎？實做起來也很簡單，在配置頁面那個步驟，將指令改成

    :::bash
    convert page-???.* -background white -splice 20x0 \
                -gravity east -splice 280x0 \
                -gravity north -splice 0x80 -append \
                -gravity south -splice 0x80 result.png

然後再將 result.png 轉成 PDF 即可。

![把頁面全部串起來]({static}/img/015.png)

能做的事情變多，哎呀，開心死了～
