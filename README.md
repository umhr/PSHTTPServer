何か動作確認やテスト用WebServerなら、PowerShellもアリなのでは？？ということで作ってみた。

【つけた機能】
* ポートが開いているかのチェック
* httpheaderにContent-Type、Access-Control-Allow-Origin、ETagをつける
* publicだけでなく外部ドライブへのアクセス
* 設定ファイル(settings.json)を読む
* data.jsonを読んだり、書き換えたり
* acme-challengeが来たらとりあえず返す

【課題】
* html上にたくさんのimgファイルをはりつけて、そのページが読み終わる前に別なページを開こうとすると落ちる。
* キャンセル処理？が必要なのかな。

【参考】
* PowerShellでGETとPOST可能な簡易Webサーバを立てる
  * https://qiita.com/payaneco/items/b4b9ff5dd8eee43e0aaa

* PowerShellでlocalhostを立ててみたらWebサーバの動きがちょっぴりわかったので紹介したい
  * https://qiita.com/S_Kosaka/items/04d875d9430f9a09b72d

* PowershellでhttpServer的なモノを作る(1)
  * https://zenn.dev/urinco/articles/f910d1921ca839

* PowerShellでJSON操作マスター：データ処理を劇的に簡単に
  * https://qiita.com/Tadataka_Takahashi/items/2f6813ff57bb24dbb8cb

* .NETを使った簡易HTTPサーバーの実装
  * https://ivis-mynikki.blogspot.com/2011/02/nethttp.html
