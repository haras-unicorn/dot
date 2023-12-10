scripts := absolute_path('scripts')
root := absolute_path('')

format:
	shfmt --write {{root}}
	prettier --write {{root}}

lint:
	shellcheck {{scripts}}/*
	prettier --check {{root}}

part *args:
	"{{scripts}}"/part {{args}}

mkpasssecrets *args:
	"{{scripts}}"/mkpasssecrets {{args}}

mksopssecrets *args:
	"{{scripts}}"/mksopssecrets {{args}}

mksshsecrets *args:
	"{{scripts}}"/mksshsecrets {{args}}

mkvpnsecrets *args:
	"{{scripts}}"/mkvpnsecrets {{args}}

mksops *args:
	"{{scripts}}"/mksops {{args}}
