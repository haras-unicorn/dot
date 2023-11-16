scripts := absolute_path('scripts')

format:
	prettier --write .
	shfmt --write .

lint:
	shellcheck {{scripts}}/*
	prettier --check .
