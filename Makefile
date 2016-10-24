test: vim-themis
	vim-themis/bin/themis --reporter spec test

vim-themis:
	git clone https://github.com/thinca/vim-themis vim-themis

.PHONY: test
