source $KIBI2_REPO_ROOT/tests/common.vim

" ===== NG case =====
new

CASE : repeat tap -> repeat repeat
lua require "run_1"

CASE : repeat repeat -> tap repeat
lua require "run_2"

call Snapshot({ 'desc': 'NG case' })
