####################################################
## .cabalやインストーラ以外からPandocをインストールした場合は
## 任意のパスを記入してください。
### 例) property pathtopandoc "/usr/local/bin/pandoc"

property pathtopandoc : ""

####################################################

global CSS

on loadScript(path)
	try
		return load script file path
	on error number n
		if (n = -43) then
			display dialog "ファイルが見つかりません" buttons {"OK"} default button 1 with icon 2
			error
		else if (n = -192) then
			display dialog "ロードしようとしているファイルはスクリプトファイルではありません。" buttons {"OK"} default button 1 with icon 2
			error
		else if (n = -39) then
			display dialog "ファイルの中身が空っぽです。" buttons {"OK"} default button 1 with icon 2
			error
		end if
	end try
end loadScript

-- http://www.script-factory.net/XModules/index.html
-- 値が無い場合は空の文字列を返す
on value_of(an_object, a_label)
	try
		return (make_with(a_label))'s value_of(an_object)
	on error
		return ""
	end try
end value_of
on make_with(a_label)
	return run script "
on value_of(an_object)
return " & a_label & " of an_object
end value
return me"
end make_with

-- 文章中から特定の文字と指定した文字を置換
on replace(txt, findstr, substr)
	set temp to AppleScript's text item delimiters
	set AppleScript's text item delimiters to findstr
	set retList to every text item of txt
	set AppleScript's text item delimiters to substr
	set retList to retList as text
	set AppleScript's text item delimiters to temp
	return retList
end replace

-- 文章を区切ってそのリストを返す
on split(txt, delimiter)
	set temp to AppleScript's text item delimiters
	set AppleScript's text item delimiters to delimiter
	set retList to every text item of txt
	set AppleScript's text item delimiters to temp
	return retList
end split

--指定した文字を挟んでリストを結合
on bind(listhtml, bindstr)
	set temp to AppleScript's text item delimiters
	set AppleScript's text item delimiters to bindstr
	set retList to listhtml as text
	set AppleScript's text item delimiters to temp
	return retList
end bind

-- CSS専用のhtmlにcssを割り当て
on subHtml(html)
	script wrap
		property h : html
	end script
	
	-- ul > ul, ol > ul, ul > ol, ol > ol
	repeat with elem in {"ul", "ol"}
		set wrap's h to split(wrap's h, "<" & elem & ">")
		
		repeat with i from 2 to wrap's h's length
			if ((not wrap's h's item (i - 1) = "") and (not wrap's h's item (i - 1)'s last word = ">")) then
				set wrap's h's item i to "<" & elem & " style=\"" & value_of(CSS, "child" & elem) & "\">" & wrap's h's item i
			else
				set wrap's h's item i to "<" & elem & ">" & wrap's h's item i
			end if
		end repeat
		
		set wrap's h to bind(wrap's h, "")
	end repeat
	
	-- pre > code
	set wrap's h to split(wrap's h, "<pre>")
	repeat with i from 2 to wrap's h's length
		set temp to split(wrap's h's item i, "</pre>")
		set temp's item 1 to replace(temp's item 1, "<code>", "<code style=\"" & value_of(CSS, "prechildcode") & "\">")
		set temp to bind(temp, "</pre>")
		set wrap's h's item i to temp
	end repeat
	set wrap's h to bind(wrap's h, "<pre>")
	
	-- blockquote
	set wrap's h to split(wrap's h, "<blockquote>")
	
	repeat with i from 2 to wrap's h's length
		set temp to split(wrap's h's item i, "</blockquote>")
		set temp's item 1 to replace(temp's item 1, "<p>", "<p style=\"" & value_of(CSS, "bqchildp") & "\">")
		set temp to bind(temp, "</blockquote>")
		set wrap's h's item i to temp
	end repeat
	set wrap's h to bind(wrap's h, "<blockquote>")
	
	-- h1:firstchild
	set wrap's h to split(wrap's h, "</h1>")
	if (wrap's h's item 1's item 2 = "h" and wrap's h's item 1's item 3 = "1") then
		if (wrap's h's item 1's item 4 = ">") then
			set wrap's h's item 1 to replace(wrap's h's item 1 as text, "<h1>", "<h1 style=\"" & value_of(CSS, "h1first") & "\">")
		else
			set wrap's h's item 1 to replace(wrap's h's item 1 as text, "<h1", "<h1 style=\"" & value_of(CSS, "h1first") & "\"")
		end if
	end if
	set wrap's h to bind(wrap's h, "</h1>")
	
	--h1~h6[prop]
	repeat with elem in {"h1", "h2", "h3", "h4", "h5", "h6"}
		set wrap's h to replace(wrap's h, "<" & elem & " ", "<" & elem & " style=\"" & value_of(CSS, elem) & "\" ")
	end repeat
	
	-- td
	set wrap's h to replace(wrap's h, "<td" & space, "<td style=\"" & value_of(CSS, "td") & "\" ")
	
	-- th
	set wrap's h to replace(wrap's h, "<th" & space, "<th style=\"" & value_of(CSS, "tth") & "\" ")
	--セレクタ名が特殊なのでここで割り当てる
	set wrap's h to replace(wrap's h, "<th>", "<th style=\"" & value_of(CSS, "tth") & "\">")
	
	-- img
	-- styleが適用されないらしいので
	set wrap's h to split(wrap's h, "<img" & space)
	repeat with i from 2 to wrap's h's length
		set temp to split(wrap's h's item i, "/>")
		set temp's item 2 to "</div>" & temp's item 2
		set wrap's h's item i to bind(temp, "/>")
	end repeat
	set wrap's h to bind(wrap's h, "<div style=\"" & value_of(CSS, "img") & "\"><img" & space)
	
	-- Eのみ
	repeat with elem in {"h1", "h2", "h3", "h4", "h5", "h6", "p", "ul", "ol", "li", "em", "strong", "a", "hr", "blockquote", "img", "pre", "code", "table", "thead", "tbody", "tr", "td"}
		set wrap's h to replace(wrap's h, "<" & elem & ">", "<" & elem & " style=\"" & value_of(CSS, elem) & "\">")
	end repeat
	
	return wrap's h
end subHtml

on removePreCodeStyle(html)
	script wrap
		property h : html
	end script
	
	--pre
	set temphtml to split(wrap's h, "<pre")
	if (temphtml's length > 1) then
		set prestyle to split(my split(temphtml's item 2, ">")'s item 1, "style=")'s item 2 as text
		set wrap's h to replace(wrap's h, space & "style=" & prestyle, "")
	end if
	
	--code
	set temphtml to split(wrap's h, "<code")
	if (temphtml's length > 1) then
		set codestyle to {}
		repeat with i from 2 to temphtml's length
			set tempcss to split(split(temphtml's item i, ">")'s item 1, "style=")'s item 2 as text
			if (codestyle's length = 0) then set codestyle's end to tempcss
			if (not codestyle's item 1 = tempcss) then
				set codestyle's end to tempcss
				exit repeat
			end if
		end repeat
		
		repeat with elem in codestyle
			set wrap's h to replace(wrap's h, space & "style=" & elem, "")
		end repeat
	end if
	
	return wrap's h
end removePreCodeStyle

-- GUIスクリプティングが無効なら、有効にすることを勧めるメッセージを出力する
-- http://d.hatena.ne.jp/zariganitosh/20090218/1235018953
on check()
	tell application "System Events"
		if UI elements enabled is false then
			tell application "System Preferences"
				activate
				set current pane to pane "com.apple.preference.universalaccess"
				set msg to "GUIスクリプティングが利用可能になっていません。
\"補助装置にアクセスできるようにする\" にチェックを入れて続けますか？"
				display dialog msg buttons {"キャンセル", "チェックを入れて続ける"} with icon note
			end tell
			set UI elements enabled to true
			delay 1
			tell application "System Preferences" to quit
			delay 1
		end if
	end tell
end check

on maindialog()
	tell application "Evernote"
		activate
		set ret to display dialog "変換形式を指定してください：" buttons {"中止", "markdown", "html"} default button 1 with icon 2
		return ret's button returned as text
	end tell
end maindialog

on writeFile(parentdir, filename, content)
	tell application "Finder"
		if (not (exists file filename in parentdir)) then set thefile to make new file with properties {name:filename} at parentdir
		set filepath to (parentdir as text) & filename
		set openfile to open for access file filepath with write permission
		set eof openfile to 0
		
		try
			write content as «class utf8» to openfile starting at 0
		on error mes
			try
				close access openfile
			end try
			error mes
		end try
		close access openfile
		
		
		return file filepath
	end tell
end writeFile

on insertBgStyle(accountname, noteid, bodycss)
	set notedir to (((path to application support from user domain) as text) & "Evernote:accounts:Evernote:" & accountname & ":content:" & noteid & ":") as alias
	set filepath to (notedir as text) & "content.html"
	set openfile to open for access file filepath
	
	try
		set html to read openfile as «class utf8»
	on error mes
		try
			close access openfile
		end try
		error mes
	end try
	close access openfile
	
	set html to my replace(html, "<body>", "<body style=\"" & bodycss & "\">")
	return writeFile(notedir, "content.html", html)
end insertBgStyle

on findPandoc()
	tell application "Finder"
		set homedir to (path to home folder as text)
		set rootdir to my split((path to system folder as text), ":")'s item 1 & ":usr:"
		
		if ((exists folder ".cabal" in (homedir as alias)) and (exists folder "bin" in (homedir & ".cabal:" as alias)) and (exists file "pandoc" in (homedir & ".cabal:bin:" as alias))) then
			return ((homedir & ".cabal:bin:")'s POSIX path as text) & "pandoc"
		else if ((exists folder "local" in (rootdir as alias)) and (exists folder "bin" in (rootdir & "local:" as alias)) and (exists file "pandoc" in (rootdir & "local:bin:" as alias))) then
			return ((rootdir & "local:bin:")'s POSIX path as text) & "pandoc"
		else
			return pathtopandoc
		end if
	end tell
end findPandoc

on convertFIle(format, filepath)
	set pandoc to my findPandoc()
	try
		if (format = "html") then
			
			log pandoc & " -S --email-obfuscation=none -f markdown_github -t html " & filepath
			set ret to do shell script "/usr/local/bin/nkf -Lu -d -w --overwrite " & filepath
			set ret to do shell script pandoc & " -S --email-obfuscation=none -f markdown_github -t html " & filepath
		else if (format = "markdown") then
			set ret to do shell script pandoc & " -f html -t markdown --atx-headers " & filepath
		end if
	on error number n
		if (n = 127) then
			tell application "Evernote"
				display dialog "Pandocが見つかりません。madever.scpt上部にある、" & return & return & "property pathdopandoc : \"\"" & return & return & "に実行ファイルのパスを入れてください。" buttons {"OK"} default button 1 with icon 2
			end tell
			error
		end if
	end try
	return ret
end convertFIle

-- バックスラッシュの改行をスペースに変換
on toHardLineOfSpace(mdtxt)
	script wrap
		property h : my split(mdtxt, return)
	end script
	
	repeat with i from 1 to wrap's h's length
		if (not wrap's h's item i as text = "") then
			if (wrap's h's item i's last character as text = "\\") then
				set temptxt to my split(wrap's h's item i as text, "\\")
				set temptxt's last item to (space & space & space)
				set wrap's h's item i to my bind(temptxt, "")
			end if
		end if
	end repeat
	
	return bind(wrap's h, return)
end toHardLineOfSpace

on toOfficialList(mdtxt)
	script wrap
		property h : mdtxt
	end script
	
	-- "-   "で書かれたリストのスペースを3つから1つに変更
	set wrap's h to my replace(wrap's h, "-" & space & space & space, "-" & space)
	
	-- "1.  "のように書かれたリストのスペースを2つから1つに変更
	-- ちょい手抜きだなしかし
	-- あとはマーカーの前のスペースもなんとかしたいところだけど...
	set wrap's h to my replace(wrap's h, "." & space & space, "." & space)
	
	return wrap's h
end toOfficialList

-- markdownにしてもhtmlにしてもimageを維持するためにhtmlとmd形式のimageリストを返す
on getNoteImgList(html, notedir)
	script wrap
		property h : html
	end script
	
	set wrap's h to my split(wrap's h, "<img" & space)
	set imgtaglist to {}
	set imgmdlist to {}
	
	--最初に<imgで区切っておかないと普通のぶん書にsrc="なんて混ざってたらこれも置換しちゃう
	repeat with i from 2 to wrap's h's length
		set img to ("<img" & space & my split(wrap's h's item i as text, ">")'s item 1 as text) & ">" -- ex) <img alt="something" src="image.png"〜 />
		set imgalt to ""
		-- altがあるかどうか。あれば取得
		if (not (offset of "alt=\"" in img) = 0) then set imgalt to my split(my split(img, "alt=\"")'s item 2, "\"")'s item 1 as text
		
		-- ex) "imagesrc.png"
		set imgsrc to my split(my split(img, "src=\"")'s item 2, "\"")'s item 1 as text
		-- ex) ![something](imagesrc.png)
		set imgmdlist's end to "![" & imgalt & "](" & imgsrc & ")"
		-- ex) <img src="file:localhost/*/imgsrc.png" />
		set imgtaglist's end to my replace(img, "src=\"", "src=\"file://localhost" & notedir's POSIX path)
	end repeat
	
	return {taglist:imgtaglist, mdlist:imgmdlist}
end getNoteImgList

on copyNoteTxt()
	tell application "System Events"
		tell process "Evernote"
			click menu bar 1's menu bar item "Edit"'s menu "Edit"'s menu item "Select All"
			delay 0.2
			click menu bar 1's menu bar item "Edit"'s menu "Edit"'s menu item "Copy"
			delay 0.2
		end tell
	end tell
end copyNoteTxt

--初期化
on run
	check()
	
	set tmptheme to loadScript((path to scripts folder from user domain as text) & "madever:loadtheme.scpt")'s main()
	set CSS to tmptheme
	
	tell application "Evernote"
		activate
		
		-- 複数のノートを選択している場合返す
		set selectnote to selection
		if (not (count selectnote) = 1) then
			return display dialog "ノートは1つだけ選択してください" buttons {"OK"} default button 1 with icon 2
		end if
		
		set selectnote to selectnote's item 1
		set accountname to current account's name as text
		set noteid to my split(selectnote's local id, "/")'s last item as text
		set notedir to (((path to application support from user domain) as text) & "Evernote:accounts:Evernote:" & accountname & ":content:" & noteid & ":") as alias
		set htmlcontent to selectnote's HTML content as text
		set retbtn to my maindialog()
		
		if (retbtn = "中止") then
			return
		else if (retbtn = "html") then
			set notetitle to selectnote's title
			set bodycss to my value_of(CSS, "body")
			set temp to the clipboard
			set the clipboard to ""
			
			-- 直接画像を挿入
			set shc to my split(htmlcontent, "<img")
			set hcref to a reference to shc
			repeat with i from 2 to hcref's length
				set imgattr to my split(hcref's item i as text, ">")'s item 1 as text
				set imgsrc to my split(my split(imgattr, "src=\"")'s item 2 as text, "\"")'s item 1 as text
				set hcref's item i to "![](" & "file://localhost" & notedir's POSIX path & imgsrc & ")" & "<img" & hcref's item i as text
			end repeat
			set shc to my bind(shc, "")
			my writeFile(notedir, "content.html", shc)
			tell selectnote to append html ""
			
			-- クリップボードにコピー
			my copyNoteTxt()
			
			-- テキスト取得
			set txt to the clipboard
			set the clipboard to temp
			
			-- テキストエリアを選択してない場合返す
			if (txt = "") then
				display dialog "テキストエリアにカーソルを置いてスクリプトを実行してください" buttons {"ok"} default button 1 with icon 2
				my writeFile(notedir, "content.html", htmlcontent)
				return
			end if
			
			-- タイトルの位置にカーソルがあれば返す
			if (notetitle = txt) then
				set ret to display dialog "もしかしてタイトルエリアにカーソルを置いていませんか？そうであればカーソルをテキストエリアに置き直してください。" buttons {"OK", "問題ないので処理を続ける"} default button 1 with icon 2
				
				if (ret's button returned as text = "OK") then
					my writeFile(notedir, "content.html", htmlcontent)
					tell selectnote to append html ""
					return
				end if
			end if
			
			set txt to txt & return
			set filepath to my writeFile(path to temporary items from user domain, "madevertempfile", txt)
			set htmltxt to my convertFIle(retbtn, (filepath as alias)'s POSIX path)
			set htmltxt to my subHtml(htmltxt)
			set selectnote's HTML content to htmltxt
			return htmltxt
			if (not bodycss as text = "") then
				my insertBgStyle(accountname, noteid, bodycss)
				tell selectnote to append html ""
			end if
		else if (retbtn = "markdown") then
			-- なぜかpreとcodeのcssだけ残るので取り除く
			set htmlcontent to my removePreCodeStyle(htmlcontent)
			
			set filepath to my writeFile(path to temporary items from user domain, "madevertempfile", htmlcontent)
			set mdtxt to my convertFIle(retbtn, (filepath as alias)'s POSIX path)
			set mdtxt to my toHardLineOfSpace(mdtxt)
			-- 様子見だなこれ
			--set mdtxt to my toOfficialList(mdtxt)
			
			-- {taglist, mdlist}を返す
			set imglist to my getNoteImgList(htmlcontent, notedir)
			set hiddenimg to ("<div style=\"display:none;\">" & imglist's taglist as text) & "</div>"
			-- imageだけノートに挿入
			set selectnote's HTML content to hiddenimg
			--markdownのテキスト挿入
			tell selectnote to append text mdtxt
			set htmlcontent to selectnote's HTML content
			
			-- ![](somethin.png)の文字列を<img ~ />形式にする
			set mdimgref to a reference to imglist's mdlist
			set tagimgref to a reference to imglist's taglist
			repeat with i from 1 to mdimgref's length
				set htmlcontent to my replace(htmlcontent, mdimgref's item i, tagimgref's item i)
			end repeat
			
			-- hiddenで保存しておいたimgを削除
			set htmlcontent to my replace(htmlcontent, hiddenimg, "")
			
			-- <html>や<body>タグがあるとHTML contentに直接挿入したときに全て一新される
			-- すると<img src="file://localhost ~ />で対策していても画像が消えてしまう。そこでsmartにしてhtmlタグやbodyタグを排除する
			-- これより前に set selectnote's HTML content to hiddenimgをしているので<body>で問題ない
			set smarthtml to my split(my split(htmlcontent, "</body>")'s item 1, "<body>")'s item 2
			set selectnote's HTML content to smarthtml
			tell selectnote to append html ""
		end if
	end tell
end run