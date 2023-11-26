scripts := absolute_path('scripts')
root := absolute_path('')

format:
	shfmt --write {{root}}
	prettier --write {{root}}

lint:
	shellcheck {{scripts}}/*
	prettier --check {{root}}
