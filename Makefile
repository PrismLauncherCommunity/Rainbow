ID := rainbow
VERSION := develop
LOADER := quilt
MINECRAFT := 1.19.2

default:
	@echo "No Default make command configured"
	@echo "Please use either"
	@echo "   - make export-mrpack"
	@echo "   - export-server"
	@echo "   - make technic"
	@echo "   - make all"
	@echo ""
	@echo "Modrinth will make a Modrinth compatible mrpack"
	@echo ""
	@echo "All will make all packs it can"
	@echo ""

export-mrpack:
	@echo "Making ${MINECRAFT} Modrinth pack"
	-mkdir build
	cd build && pw modrinth export --pack-file ../pack/${MINECRAFT}/pack.toml

run-server:
	@echo "Starting Dev Server"
	wget -nc https://github.com/packwiz/packwiz-installer-bootstrap/releases/download/v0.0.3/packwiz-installer-bootstrap.jar -P build/server
	wget -nc https://meta.fabricmc.net/v2/versions/loader/1.20.1/0.14.22/0.11.2/server/jar -O build/server/devel-server.jar
	go run server.go ${MINECRAFT}
	echo "eula=true" > build/server/eula.txt
	cd build/server && java -jar devel-server.jar nogui

upload-modrinth:
	sed -i -e '/version =/ s/= .*/= "${VERSION}"/' pack/${MINECRAFT}/pack.toml
	make modrinth
	make curseforge
	make quilt-server
	ID=${ID} VERSION=${VERSION} LOADER=${LOADER} MINECRAFT=${MINECRAFT} MODRINTH_TOKEN=${MODRINTH_TOKEN} gradle modrinth

clean:
	-rm -rf build/
	sed -i -e '/version =/ s/= .*/= "${VERSION}"/' ./pack/pack.toml
	-git gc --aggressive --prune

update-packwiz:
	go install github.com/packwiz/packwiz@latest

all: modrinth prism server clean