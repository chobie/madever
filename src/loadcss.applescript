#######################################
# 読み込むファイル名を""の間に記入してください

property cssfilename : "simple.css"

#######################################

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

-- http://d.hatena.ne.jp/zariganitosh/20111005/coding_value_world
on set_key(a_record, a_key, a_value)
	return (run script "{|" & a_key & "|:" & a_value & "}") & a_record
end set_key

on lfcr(txt, lf, cr)
	set txt to split(txt, lf)
	set txt to split(txt, cr)
	return txt
end lfcr

-- http://www.script-factory.net/XModules/index.html
on value_of(an_object, a_label)
	try
		set t to (make_with(a_label))'s value_of(an_object)
		return true
	on error
		return false
	end try
end value_of
on make_with(a_label)
	return run script "
on value_of(an_object)
return " & a_label & " of an_object
end value
return me"
end make_with

on main()
	set loadfile to ""
	set cssdata to ""
	set tmp to {}
	set loadfile to (path to scripts folder from user domain as string) & "madever:css:" & cssfilename as alias
	set openfile to open for access loadfile
	
	try
		set cssdata to read openfile as «class utf8»
	on error number n
		close access openfile
		if (n = -43) then
			return display dialog "ファイルが見つかりません。loadcss.scptの名前を確認してください。" buttons {"OK"} default button 1 with icon 2
		else if (n = -39) then
			return display dialog "ファイルの中身が空です。cssを書いてください。" buttons {"OK"} default button 1 with icon 2
		end if
	end try
	close access openfile
	
	-- LF CR
	set cssdata to lfcr(cssdata, (ASCII character "10") & (ASCII character "10"), (ASCII character "13") & (ASCII character "13"))
	script wrap
		property css : cssdata
	end script
	
	set starselecter to ""
	repeat with elem in wrap's css
		set alist to lfcr(elem as text, (ASCII character "10"), (ASCII character "13"))
		set star to alist's item 1 as text
		if (star = "*") then set starselecter to bind(alist's rest, "")
	end repeat
	
	repeat with i from 1 to wrap's css's length
		set elem to wrap's css's item i
		-- LF CR
		set elem to lfcr(elem, (ASCII character "10"), (ASCII character "13"))
		set selecter to elem's item 1 as text
		set cssprop to bind(elem's rest, "") as text
		
		-- starselecterのプロパティを適用
		if (not (selecter = "h1first" or selecter = "childul" or selecter = "childol" or selecter = "bqchildp" or selecter = "prechildcode")) then
			if (not cssprop = "") then
				set cssprop to starselecter & cssprop
			end if
		end if
		
		set tmp to set_key(tmp, selecter, "\"" & cssprop & "\"")
	end repeat
	
	-- 特別なセレクタ
	if (value_of(tmp, "h1first")) then set tmp's h1first to tmp's h1 & tmp's h1first
	if (value_of(tmp, "childul")) then set tmp's childul to tmp's ul & tmp's childul
	if (value_of(tmp, "childol")) then set tmp's childol to tmp's ol & tmp's childol
	if (value_of(tmp, "bqchildp")) then set tmp's bqchildp to tmp's p & tmp's bqchildp
	if (value_of(tmp, "prechildcode")) then set tmp's prechildcode to tmp's code & tmp's prechildcode
	
	return tmp
end main