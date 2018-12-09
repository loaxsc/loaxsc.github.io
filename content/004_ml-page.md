Title: 利用 FreePic2Pic 製作多層 PDF
Date: 2018-12-09
Category: article

# 利用 FreePic2Pic 製作多層 PDF

在看 FreePic2Pdf 的說明文件時發現 FreePic2Pdf 有作多層 PDF 的功能，這功能使黑白文字混搭彩色插圖成為可能，我忍不任嘗試了一下。

因為將文字部分轉成黑白圖片一定要放大效果才好，連帶著插圖也要放大。為了避免增加太多檔案體積，用 Imagemagick 放大插圖時採用 -scale 的方式。換句話說就是先用 -resize 把圖片放大一輪，然後找出有插圖的部分，用 -scale 放大後取出插圖，並將座標資料存入 page_with_pic.info 中。

要用 FreePic2Pdf 做混搭的多層PDF的話，除了要製作FreePic2Pdf.itf這個文件，檔案命名還要符合它的要求。這個環節讓我卡超久，因為還有一個條件在 FreePic2Pdf 說明文件中沒提。它還要求多層頁面必須有一個同名的圖檔，就是說除了 page1.000 page1.001 page1.002...之外，還需要有一個 page1.png 或 page1.jpg 之類的圖檔，否則即使 FreePic2Pdf.itf 中有設定，而且檔案也存在，製作出來的 PDF 還是會缺頁。

FreePic2Pdf 在製作 PDF 時應該是根據圖檔是否存在判斷有沒有該頁面，然後再配對 FreePic2Pdf.itf 中的設定決定如何處理。原本 FreePic2Pdf 是作者寫來處理 PDG 工具組的一部分，如果說一路跟上來，即使文件中沒註明，其他成員應該也猜得到，可是我是在網路上搜尋製作 PDF 的工具時找到了 FreePic2Pdf 就用了起來，我可沒辨法簡單地猜到。最後弄得沒辨法，是在網路上搜尋 PDG 檔案下來解開，才恍然大悟。

我覺得編寫 FreePic2Pic.itf 實在太麻煩了，不過我已經累積了方法製作 page_with_pic.info，就想說用 python 寫個腳本把 page_with_pic.info 轉成 FreePic2Pic.itf，順便處理好檔名，以後要用到的話就直接轉換即可。

腳本如下

```python
#! /usr/bin/python3
# -*- coding: utf-8 -*-

from PIL import Image
import sys, os, re, shutil


if __name__ == '__main__':

    f_in='page_with_pic.info'
    with open(f_in,'r') as f:
        txt=f.read().strip()

    pre_im = ''
    itf = ''
    for item in txt.split('\n'):
        im = re.findall( r'^page-\d{3}', item )[0]
        if pre_im and pre_im != im:
            itf += '{}_000=0,0,{},{}\n{}={}\n'.format( pre_im, *Image.open( pre_im + '.png' ).size, pre_im, count )
        count = count + 1 if pre_im == im else 1
        itf += re.sub( r',(\d+)x(\d+)\+(\d+)\+(\d+)', r'_{:03d}=\3,\4,\1,\2', item ).format( count ) + '\n'
        pre_im = im

    itf += '{}_000={},{},0,0\n{}={}'.format( pre_im, *Image.open( pre_im + '.png' ).size, pre_im, count )

    f_out = 'FreePic2Pdf.itf'
    with open(f_out,'w') as f:
        f.write(itf)

    iml = re.sub(r'^(page-\d{3}),(.+)',r'\1_\2.png', txt, flags=re.M )

    pre_im = ''
    for im in iml.split('\n'):
        count = count + 1 if pre_im == im else 1
        shutil.copy( 'crop-pic/' + im, '{}.{:03d}'.format( re.findall( r'^page-\d{3}', im )[0], count ) )
        if pre_im != im:
            shutil.copy( re.findall( r'^page-\d{3}',im )[0] + '.png', re.findall( r'^page-\d{3}',im )[0] + '.000' )

    exit(0)
```

將圖檔和 FreePic2Pic.itf 準備好後，用 FreePic2Pic 轉出來，效果還不錯，不輸其他的方法

![ txt2-pic16 的效果圖]({static}/img/037.png)

只是 PDF 的體積沒想像中的小。算了，就是一個嘗試而已。

![ txt2-pic16 的檔案尺寸 ]({static}/img/038.png)
