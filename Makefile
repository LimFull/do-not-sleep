.PHONY: build app dmg clean

build:
	swift build

app:
	./scripts/build-app.sh

dmg: app
	./scripts/create-dmg.sh

clean:
	swift package clean
