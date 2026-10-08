source $KIBI2_REPO_ROOT/tests/common.vim

" ===== NG case =====
new

CASE : repeat tap -> repeat repeat
lua require "run_1"

CASE : repeat repeat -> repeat tap
lua require "run_2"

CASE : tap tap -> tap repeat
lua require "run_3"

CASE : tap hold -> hold hold
lua require "run_4"

CASE : hold repeat -> tap repeat
lua require "run_5"

call Snapshot({ 'desc': 'NG case' })
