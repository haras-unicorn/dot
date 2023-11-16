scripts := absolute_path('scripts')
root := absolute_path('')

format:
	prettier --write {{root}}
	shfmt --write {{root}}

lint:
	shellcheck {{scripts}}/*
	prettier --check {{root}}
