CHANGELOG := update
VERSION := develop
MINECRAFT := 1.19.2

default:
	@echo "No Default make command configured"
	@echo "Please use either"
	@echo "   - make curseforge"
	@echo "   - make modrinth"
	@echo "   - make prism"
	@echo "   - make technic"
	@echo "   - make all"
	@echo ""
	@echo "Curseforge will make a curseforge compatible zip"
	@echo ""
	@echo "Modrinth will make a Modrinth compatible mrpack"
	@echo ""
	@echo "All will make all packs it can"
	@echo ""
	
curseforge:
	@echo "Making ${MINECRAFT} Curseforge pack"
	-mkdir build
	cd build && packwiz curseforge export --pack-file ../pack/${MINECRAFT}/pack.toml

modrinth:
	@echo "Making ${MINECRAFT} Modrinth pack"
	-mkdir build
	cd build && packwiz modrinth export --pack-file ../pack/${MINECRAFT}/pack.toml

quilt-server:
	@echo "Making Server pack"
	sed -i -e '/MINECRAFT=/ s/= .*/="${MINECRAFT}"/' ./server/start.sh
	wget -nc https://maven.quiltmc.org/repository/release/org/quiltmc/quilt-installer/latest/quilt-installer-latest.jar -P build
	cd build && java -jar quilt-installer-latest.jar \
  	install server ${MINECRAFT} \
  	--download-server
	-rm build/quilt-installer-latest.jar
	-cp -r ./server ./build/server

release:
	sed -i -e '/VERSION=/s/=.*/="release"/' server/start.sh
	sed -i -e '/VERSION=/s/=.*/="release"/' server/start.bat
	sed -i -e '/version =/ s/= .*/= "${VERSION}"/' pack/${MINECRAFT}/pack.toml
	make modrinth
	make curseforge
	make quilt-server
	NAME=${NAME} ID=${ID} CHANGELOG=${CHANGELOG} MINECRAFT=${MINECRAFT} MODRINTH_TOKEN=${MODRINTH_TOKEN} gradle modrinth

clean:
	-rm -rf build/
	sed -i -e '/VERSION=/s/=.*/="develop"/' server/start.sh
	sed -i -e '/VERSION=/s/=.*/="develop"/' server/start.bat
	sed -i -e '/version =/ s/= .*/= "${VERSION}"/' pack/pack.toml
	-git gc --aggressive --prune

update:
	go install github.com/packwiz/packwiz@latest

all: curseforge modrinth prism server clean