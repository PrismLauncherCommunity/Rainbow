ID := rainbow
VERSION := develop
LOADER := quilt
MINECRAFT := 1.19.2

default:
	@echo "No Default make command configured"
	@echo "Please use either"
	@echo "   - make modrinth"
	@echo "   - make prism"
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

export-server:
	@echo "Making Server pack"
	sed -i -e '/MINECRAFT=/ s/= .*/="${MINECRAFT}"/' server/start.sh
	-mkdir build
	wget -nc https://quiltmc.org/api/v1/download-latest-installer/java-universal -O build/quilt-installer.jar
	cd build && java -jar quilt-installer.jar \
  	install server ${MINECRAFT} \
  	--download-server
	wget -nc https://github.com/packwiz/packwiz-installer-bootstrap/releases/download/v0.0.3/packwiz-installer-bootstrap.jar -P build/server
	-rm build/quilt-installer.jar

run-server:
	@echo "Starting Dev Server (make sure to run export-server first)"
	go run server.go ${MINECRAFT}
	echo "eula=true" > build/server/eula.txt
	cd build/server && java -jar quilt-server-launch.jar nogui

upload-modrinth:
	sed -i -e '/VERSION=/s/=.*/="release"/' server/start.sh
	sed -i -e '/VERSION=/s/=.*/="release"/' server/start.bat
	sed -i -e '/version =/ s/= .*/= "${VERSION}"/' pack/${MINECRAFT}/pack.toml
	make modrinth
	make curseforge
	make quilt-server
	ID=${ID} VERSION=${VERSION} LOADER=${LOADER} MINECRAFT=${MINECRAFT} MODRINTH_TOKEN=${MODRINTH_TOKEN} gradle modrinth

clean:
	-rm -rf build/
	sed -i -e '/VERSION=/s/=.*/="develop"/' ./server/start.sh
	sed -i -e '/VERSION=/s/=.*/="develop"/' ./server/start.bat
	sed -i -e '/version =/ s/= .*/= "${VERSION}"/' ./pack/pack.toml
	-git gc --aggressive --prune

update-packwiz:
	go install github.com/packwiz/packwiz@latest

all: modrinth prism server clean