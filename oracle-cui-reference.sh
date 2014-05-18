# oracle-cui-reference.sh
#
# Script to view oracle database reference manual by cui.
#
# This script provide two functions.
# First, download online html manual and convert for reading.
# Second, can read converted online manual with optional viewer.
#
# Copyright (c) 2012,2014 Kazuhiro Yoshikawa <yoshikaw@gmail.com>
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

##############################################################################
#
# Usage
#   1) Read this script in the current b-shell environment.(bash or zsh)
#       $ source /path/to/oracle-cui-reference.sh
#
#   2) Make converted data with omkdata function.
#       $ omkdata { 102 | 111 | 112 | 121 | all }
#
#      omkdata function requires one argument
#      such as release version:
#
#        121 - Oracle Database 12c Release 1 (12.1)
#        112 - Oracle Database 11g Release 2 (11.2)
#        112 - Oracle Database 11g Release 2 (11.2)
#        111 - Oracle Database 11g Release 1 (11.1)
#        102 - Oracle Database 10g Release 2 (10.2)
#        all - all of the above
#
#      this function relies on wget and w3m.
#
#   3) View converted data using following functions.
#
#        owhat    - What's New / Changes in This Release
#        oinit    - Initialization Parameters
#        ostat    - Static Data Dictionary Views
#        odyn     - Dynamic Performance Views (V$)
#        olimits  - Database Limits
#        oscripts - SQL Scripts
#        owait    - Oracle Wait Events
#        oenq     - Oracle Enqueue Names
#        ostats   - Statistics Descriptions
#        obg      - Background Processes
#
#      these functions recognize two optional arguments.
#
#        o???? [ [ 102 | 111 | 112 | 121 ] search_word ]
#
#      The first argument specify target release version.
#      If this omitted, using ODOC_RELVER variable. (default: 112)
#
#      The second argument used for searching word. This argument
#      become effective if $ODOC_VIEWER indicates vi or view or vim.
#
# Options
#   The following shell variables affects the execution of functions:
#
#   ODOC_CACHE_DIR
#     The location of download file and converted file is stored.
#     (default: $HOME/.odoc_cache)
#
#   ODOC_VIEWER
#     The name of the viewer program to use for display the manual.
#     (default: $PAGER or more)
#
#   ODOC_RELVER
#     The number of product version to be used as the default.
#     (default: 112)
#
#   ODOC_LANG
#     The language of a document to be manipulated.
#     Currentry supports "en", "ja".
#     (default: ja)
#
#   ODOC_SHRINK
#     The level of shrink original documents.
#       0: Don't shrink.
#       1: Shrink blank lines on a table.
#       2: In addition to above, shrink ruled lines on a table.
#       3: In addition to above, shrink blank lines on a whole document.
#
#     This variable used by omkdata function only.
#     (default: 3)
#
#   ODOC_DYN
#     Enables dynamic conversion to display the manual.
#     This parameter is useful to view a different terminal width when you convert.
#     This parameter is useful when you are using a different terminal width when you convert.
#     (default: 0)
#
##############################################################################

: ${ODOC_CACHE_DIR:=$HOME/.odoc_cache}
: ${ODOC_VIEWER:=${PAGER:=more}}

: ${ODOC_RELVER:=112}
: ${ODOC_LANG:=ja}

: ${ODOC_SHRINK:=3}
: ${ODOC_DYN:=0}

# define document infomartion {{{
if [[ -n "$ZSH_VERSION" ]]; then
  typeset -ga __odoc
else
  declare -a __odoc
fi
# [format]      1 original document encoding [u]utf8 [s]shift_jis
#               |23 starting line number of contents
#               || 45 ending line number of contents
#               || | 6- document url base
__odoc[102000]='u0604http://docs.oracle.com/cd/B19306_01/server.102/b14237'
__odoc[111000]='u0604http://docs.oracle.com/cd/B28359_01/server.111/b28320'
__odoc[112000]='u0604http://docs.oracle.com/cd/E11882_01/server.112/e25513'
__odoc[121000]='u0604http://docs.oracle.com/cd/E16655_01/server.121/e17615'
__odoc_lang_en='000'

__odoc[102001]='s0702http://otndnld.oracle.co.jp/document/products/oracle10g/102/doc_cd/server.102/B19228-04'
__odoc[111001]='s0702http://otndnld.oracle.co.jp/document/products/oracle11g/111/doc_dvd/server.111/E05771-04'
__odoc[112001]='u0602http://docs.oracle.com/cd/E16338_01/server.112/b56311'
__odoc[121001]='u0602http://docs.oracle.com/cd/E49329_01/server.121/b71292'
__odoc_lang_ja='001'
#}}}

function __odoc_lang()       { eval "echo \$__odoc_lang_${ODOC_LANG}"; }

function __odoc_encoding()   { echo    $(__odoc_substr ${__odoc[$relver$lang]} 0 1); }
function __odoc_start_line() { echo $[ $(__odoc_substr ${__odoc[$relver$lang]} 1 2) ]; }
function __odoc_end_line()   { echo $[ $(__odoc_substr ${__odoc[$relver$lang]} 3 2) ]; }
function __odoc_url_base()   { echo    $(__odoc_substr ${__odoc[$relver$lang]} 5); }

function __odoc_upper() { #{{{
  if [[ -n "$ZSH_VERSION" ]]; then
    echo ${(U)1}
  else
    echo "$1" | tr a-z A-Z
  fi
} #}}}

function __odoc_substr() { #{{{ bash compatible substring for older version of zsh (<= 4.1.10)
  local string=$1
  local offset=${2:-0}
  local length=${3:-${#string}}
  if [[ -n "$ZSH_VERSION" ]]; then
    echo ${string[offset + 1, offset + length]}
  else
    echo ${string:offset:length}
  fi
} #}}}

function __odoc_set_terminal_title() { #{{{
  echo -ne "\033]0;$1\007"
  [[ -n "$STY" ]] && echo -ne "\033k$1\033\0134" # Change a window title of GNU Screen
} #}}}

function __odoc_filter() { #{{{
  local filter

#  [[ $ODOC_SHRINK -eq 1 ]] && filter="${filter}s/^(\s|\xA8(\xA1|\xA2|\xA7|\xA9|\xAB))+$//g;"
  [[ $ODOC_SHRINK -ge 1 ]] && filter="${filter}s/^\s*\xA8\xA2(\s|\xA8\xA2)+$//g;"  # shrink blank line on table
  [[ $ODOC_SHRINK -ge 2 ]] && filter="${filter}s/^\s*\xA8\xA7(\s|\xA8(\xA1|\xA2|\xA7|\xA9|\xAB))+$//g;" # shrink only ruled line on table
  [[ $ODOC_SHRINK -ge 3 ]] && filter="${filter}s/^\s+$//g;" # shrink blank line

  case "$ODOC_LANG" in
  "en")
    # Remove line of navigation
    filter="${filter}s/^Skip Headers.*\n$//;"
    filter="${filter}s/^The script content on this page is for navigation purposes only and does not alter the content in any way.\n$//;"
    filter="${filter}s/^Press the \"Next\" button to go to the.*\n$//;"
    filter="${filter}s/^.*Legal Notices.*\n$//;"

    filter="${filter}s/^\s*(Go to|[Nn]ext|[Pp]revious|page)\s*(Go( to)?|to|[Nn]ext|page)?\s*(PDF.*ePub)?\s*\n$//;"
    filter="${filter}s/^Scripting on this page enhances content navigation, but does not change the content in any way.\n$//;"

    # Remove navigate strings
    filter="${filter}s/^\s+(Go( to)?\s+)+//;"
    filter="${filter}s/\s+(Go( to)?\s+)+$/\n/;"
#    filter="${filter}s/^\s+(Go( to)? *)+$//;"
#    filter="${filter}s/\s*(Go( to)? *)//;"
##    filter="${filter}s/^\s*([Pp]revious\s+(to|[Nn]ext)|page\s+(next|page))\s*//;"
##    filter="${filter}s/^\s*(Next\s+)?(Home\s+|List\s+Contents\s+|Master\s+Contact|Book\s+Index\s+Us|List)+ *\n//;"
##    filter="${filter}s/\s*([Pp]revious\s+(to|[Nn]ext)|page\s+(next|page))\s*//;"
    filter="${filter}s/^\s*([Pp]revious\s+(to|page|[Nn]ext)|page\s+(next|page))\s*//;"
    if [ $COLUMNS -gt 100 ]; then
      filter="${filter}s/^\s*(Next\s+)?(Home\s+|List\s+Contents\s+|Master\s+Contact|Book\s+Index\s+Us|List)+ *\n//;"
    else
      :
    fi
    filter="${filter}s/\s*(Next\s+)?(Home\s+|List\s+Contents\s+|Master\s+Contact|Book\s+Index\s+Us|List)+ *//;"
    filter="${filter}s/\s+Documentation\s+to\s+Table of\s+Index\s+Master\s+Feedback(\x20)*//;"
    filter="${filter}s/\s*(Home\s+)?Book\s+Contents\s+Index\s+Index\s+page?(\x20)*//;"
    ;;
  "ja")
    filter="${filter}s/^\xa5\xd8\xa5\xc3\xa5\xc0\xa1\xbc\xa4\xf2\xa5\xb9.*\n$//;"             # 'ヘッダーをスキップ'
    if [[ "$(__odoc_encoding)" = 'u' ]]; then
      # Remove line of navigation
      filter="${filter}s/^\xa4\xb3\xa4\xce\xa5\xda\xa1\xbc\xa5\xb8\xa4\xce.*\n$//;"           # 'このページのスクリプト・コンテンツは...'
      filter="${filter}s/^\xa1\xd6\xbc\xa1(\xa4\xd8)?\xa1\xd7\xa5\xdc\xa5\xbf.*\n$//;"        # '「次へ」ボタンをクリックすると、...'
      filter="${filter}s/^.*\xcb\xa1\xce\xa7\xbe\xe5\xa4\xce\xc3\xed\xb0\xd5\xc5\xc0.*\n$//;" # '法律上の注意点...'

      # Remove navigate strings ' 前 次 '
      filter="${filter}s/\s*\xc1\xb0(\x20)+\xbc\xa1\s*//;"
    else
      # Remove navigate strings ' 戻る 次へ '
      filter="${filter}s/\s*\xcc\xe1\xa4\xeb(\x20)*\xbc\xa1\xa4\xd8\s*//;"

      filter="${filter}s/ +$//;"
    fi

    # Remove navigate strings ' 目次(へ移動) 索引(へ移動) '
    filter="${filter}s/\s*\xcc\xdc\xbc\xa1(\xa4\xd8\xb0\xdc\xc6\xb0)?(\x20)+\xba\xf7\xb0\xfa(\xa4\xd8\xb0\xdc\xc6\xb0)?(\x20)*//;"
    ;;
  esac
  # Remove left spaces
  filter="${filter}s/\s*Copyright /Copyright /;"

  # Remove line feed
  filter="${filter}s/(Oracle Corporation\.)\s*$/\$1 /;"
  filter="${filter}s/(Oracle and\/(or its)?)\s*$/\$1/;"

  # Remove line of alternate logo text 'Oracle(ロゴ)'
  filter="${filter}s/^\s*Oracle(\xa5\xed\xa5\xb4)?\s*$//;"

  # Recover symbol string that cannot be converted to euc-jp encoding
  filter="${filter}s/^Oracle\?+ /Oracle(R) /;"
  filter="${filter}s/Copyright \?+/Copyright (C)/;"

  # Replace the ambiguous characters that cannot be converted to euc-jp encoding
  filter="${filter}s/\xA1\xDD/\x2D\x20/g;"

  echo "| perl -pi -e '$filter'"
} #}}}

function __odoc_download() { #{{{
  local url=$1
  local file=$2
  [[ -d ${file%/*} ]] || mkdir -p ${file%/*}
  wget -qN $url -O $file
} #}}}

function __odoc_view() { #{{{
  local cols=$[ ${ODOC_COLUMNS:-${COLUMNS:-90}} - 1 ]
  local page=$1
  local relver=$ODOC_RELVER
  case $# in
    1) ;;
    2) case $2 in 102|111|112|121) relver=$2; shift;; esac;;
    *) relver=$2; shift;;
  esac
  local lang="$(__odoc_lang)"
  local url="$(__odoc_url_base)/$page"
  local word=$(__odoc_upper "$2")
  local file="$ODOC_CACHE_DIR/${url#http://}.txt"
  local cmdline
  if [[ "$ODOC_DYN" -eq 1 ]]; then
    file=${file%.htm.txt}.merged.html
    cmdline="w3m -dump \"file://$file\" -t 4 -S -I$(__odoc_encoding) -Oe -cols $cols $(__odoc_filter) |"
  fi
  [[ -f "$file" ]] || { echo "file not found. $file"; return 1; }
  [[ "$ODOC_DYN" -eq 1 ]] && file=

  if [[ -z "${ODOC_VIEWER##vi*}" ]]; then
    word=${word:+"+/$word"}
    file=${file:="-"}
  else
    word=
  fi
  __odoc_set_terminal_title "${page%%.*}($relver ${ODOC_LANG})"
  eval "$cmdline $ODOC_VIEWER $file $word"
  __odoc_set_terminal_title "${USER}@${HOSTNAME%%.*}:${PWD/#$HOME/~}"
} #}}}

function omkdata() { #{{{
  local cols=$[ ${ODOC_COLUMNS:-${COLUMNS:-90}} - 1 ]
  local relver
  case $1 in
    102|111|112|121) relver=$1;;
    all) for relver in 102 111 112 121; do omkdata $relver; done; return;;
    *)
      echo "Usage: omkdata { 102 | 111 | 112 | 121 | all }"
      return 1
  esac
  local lang="$(__odoc_lang)"
  local url="$(__odoc_url_base)/toc.htm"

  local toc=$ODOC_CACHE_DIR/${url#*://}
  local cachedir=${toc%/*}
  [[ -f "$toc" ]] || __odoc_download "$url" "$toc" || return $?

  local p
  local -a pages; pages=(whatsnew initparams statviews dynviews limits scripts waitevents enqueues stats bgprocesses)
###  local -a pages; pages=(initparams)

  # initialize files
  for p in ${pages[@]}
  do
    echo -n > $cachedir/${p}.htm.txt
    echo "<html><body>" > $cachedir/${p}.merged.html
  done

### debug
###find $cachedir \( -name '*.tmp' -o -size -30c \) -print0 | xargs -0 rm

  local filter="$(__odoc_filter)"
  local encoding="$(__odoc_encoding)"
  local start_line="$(__odoc_start_line)"
  local end_line="$(__odoc_end_line)"

  local lines_of_header=$[ start_line - 2 ]
  [[ $ODOC_SHRINK -ge 3 ]] && (( start_line--, end_line=2 ))

  local lines_of_frame=$[ start_line + end_line - 2 ]
  local lines_of_footer=$[ end_line - 1 ]

  local convert_title=0
  [[ "$encoding" = "s" ]] && type iconv > /dev/null 2>&1 && convert_title=1

  p=${pages[*]}
  [[ $relver = 121 ]] && p="$p release_changes.htm refrn[0123][[:digit:]]{4}.htm refrn004[[:digit:]].htm refrn00[789].htm"
  grep -E "<a href=\"(${p// /|})" $toc \
    | perl -pi -e 's{.*href="([^#"]+)?.*?">(?:(?:<span class="secnum">[^<]+</span>|\w?&nbsp;) +)?([^<]+)(?:<(?:span|em) class="italic">([^<]+)?</(?:span|em)>)?(.*)?</a>(?:<.*)?}{$1 $2$3}i' \
    | while read file title
  do
    cachefile=$cachedir/$file
    indexfile=$cachedir/${file//[0-9_]/}.txt
    if [[ $relver -ge 121 ]]; then
      case $file in
        release_changes.htm)             indexfile=$cachedir/whatsnew.htm.txt;;
        refrn[01]????.htm)               indexfile=$cachedir/initparams.htm.txt;;
        refrn00[789].htm|refrn2????.htm) indexfile=$cachedir/statviews.htm.txt;;
        refrn3????.htm)                  indexfile=$cachedir/dynviews.htm.txt;;
        refrn004?.htm)                   indexfile=$cachedir/limits.htm.txt;;
      esac
    fi
    mergefile=${indexfile%.htm.txt}.merged.html

    indexname=${indexfile##*/}
    __odoc_set_terminal_title "omkdata($relver $ODOC_LANG) ${indexname%%.*}"

    [[ -f "$cachefile" ]] || __odoc_download "${url%/*}/$file" "$cachefile"

    if [[ -f "$cachefile" ]]; then
      tmpfile=${cachefile}.tmp
      if ! [[ -s "$tmpfile" ]]; then
        cmdline="w3m -dump \"file://$cachefile\" -t 4 -S -I$encoding -Oe -cols $cols $filter"
        eval $cmdline > $tmpfile
        [[ -s $tmpfile ]] || return 1

        # output header first
        [ -s $indexfile ] || head -n $lines_of_header $tmpfile > $indexfile

        # output contents
        lines=$(cat $tmpfile | wc -l)
        [[ $convert_title -eq 1 ]] && title="$(echo $title | iconv -f SJIS -t ${LANG#*.} 2> /dev/null)"

        printf "(%3d %2s) %-15s | %5d %-20s | %s\n" $relver $ODOC_LANG ${indexname%%.*} $lines $file "$title"
        tail -n +$start_line $tmpfile | head -n +$[ lines - lines_of_frame ] >> $indexfile

#printf "-- DEBUG: lines: %d, h:%d c:%d f:%d \n" $lines $lines_of_header $lines_of_frame $lines_of_footer >> $indexfile

        # output footer in order to merge later
        tail -n $lines_of_footer $tmpfile | head -n 1 > ${indexfile}.footer.tmp

###debug
###[[ $(wc -c < $indexfile) -gt 100000 ]] && break

        # merge html file
        lines=$(cat $cachefile | wc -l)
        start=$(grep -n 'id="BEGIN"' $cachefile | cut -d: -f1)
        end=$(grep -nE '^<!-- Start Footer -->|<div class="footer">' $cachefile | head -n 1 | cut -d: -f1)
#        tail -n +$start $cachefile | head -n +$[ lines - end ] >> $mergefile
        tail -n +$[ lines - start + 1 ] $cachefile | head -n +$[ end - ( lines - start ) - 1 ] >> $mergefile
        echo "<hr/>" >> $mergefile
        tail -n +$end $cachefile > ${mergefile}.footer.tmp
      fi
    fi
  done
  [[ $? -eq 0 ]] || return $?

  # terminate files
  local basename
  for p in ${pages[@]}
  do
    basename=$cachedir/$p
    if [[ -f "${basename}.merged.html.footer.tmp" ]]; then
      cat "${basename}.merged.html.footer.tmp" >> ${basename}.merged.html
    else
      echo "</body></html>" >> ${basename}.merged.html
    fi
    if [[ -f "${basename}.htm.txt.footer.tmp" ]]; then
      cat ${basename}.htm.txt.footer.tmp >> ${basename}.htm.txt
    fi
  done

  # make shortcut
  local shortcut=$ODOC_CACHE_DIR/$relver$ODOC_LANG
  rm -f $shortcut; ln -s $cachedir $shortcut

  find $cachedir \( -name '*.tmp' -o -size -30c \) -print0 | xargs -0 rm
###  find $cachedir \( -name '*.txt' -o -name '*.merged.html' \) | xargs ls -l

  __odoc_set_terminal_title "omkdata($relver $ODOC_LANG) done!"
} #}}}

function owhat()    { __odoc_view "whatsnew.htm"     $@; }
function oinit()    { __odoc_view "initparams.htm"   $@; }
function ostat()    { __odoc_view "statviews.htm"    $@; }
function odyn()     { __odoc_view "dynviews.htm"     $@; }
function olimits()  { __odoc_view "limits.htm"       $@; }
function oscripts() { __odoc_view "scripts.htm"      $@; }
function owait()    { __odoc_view "waitevents.htm"   $@; }
function oenq()     { __odoc_view "enqueues.htm"     $@; }
function ostats()   { __odoc_view "stats.htm"        $@; }
function obg()      { __odoc_view "bgprocesses.htm"  $@; }

# vim: filetype=zsh foldmethod=marker
