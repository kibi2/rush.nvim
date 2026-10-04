source $KIBI2_REPO_ROOT/tests/common.vim

" ===== BASIC =====
new

CASE : count
lua require "run1"

call Snapshot({ 'desc': 'basic' })
