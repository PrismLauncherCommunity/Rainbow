ID=rainbow
VERSION=develop
LOADER=fabric
MINECRAFT=1.20.1

BUILDDIR=build

$(BUILDDIR):
	mkdir -p $@

$(BUILDDIR)/$(MINECRAFT)/server: | $(BUILDDIR)
	@echo "Installing Fabric"
	mkdir -p $(BUILDDIR)/$(MINECRAFT)/server
	wget -nc https://maven.fabricmc.net/net/fabricmc/fabric-installer/0.11.2/fabric-installer-0.11.2.jar -O $(BUILDDIR)/fabric-installer.jar
	cd $(BUILDDIR) && java -jar fabric-installer.jar \
		server -dir $(MINECRAFT)/server -mcversion ${MINECRAFT} -downloadMinecraft
	-rm $(BUILDDIR)/fabric-installer.jar

$(BUILDDIR)/$(MINECRAFT)/server/packwiz-installer-bootstrap.jar: | $(BUILDDIR)/$(MINECRAFT)/server
	@echo "Preparing packwiz bootstrap"
	wget -nc https://github.com/packwiz/packwiz-installer-bootstrap/releases/download/v0.0.3/packwiz-installer-bootstrap.jar -P $(BUILDDIR)/$(MINECRAFT)/server

$(BUILDDIR)/$(MINECRAFT)/server/eula.txt: | $(BUILDDIR)/$(MINECRAFT)/server/packwiz-installer-bootstrap.jar
	@echo "Agreeing to EULA"
	echo "eula=true" > $(BUILDDIR)/$(MINECRAFT)/server/eula.txt

update-packwiz:
	@echo "Update packwiz"
	go install github.com/packwiz/packwiz@latest

download-mods: | $(BUILDDIR)/$(MINECRAFT)/server/packwiz-installer-bootstrap.jar update-packwiz
	@echo "Download server mods"
	packwiz --pack-file ./pack/${MINECRAFT}/pack.toml serve &
	@sleep 1
	cd $(BUILDDIR)/$(MINECRAFT)/server && java -jar packwiz-installer-bootstrap.jar -g -s server http://0.0.0.0:8080/pack.toml
	pkill packwiz

prepare-server: download-mods $(BUILDDIR)/$(MINECRAFT)/server/eula.txt

run-server: prepare-server
	@echo "Starting Dev Server"
	cd $(BUILDDIR)/$(MINECRAFT)/server && java -jar fabric-server-launch.jar nogui || echo "done" 

export-mrpack:
	@echo "Making ${MINECRAFT} Modrinth pack"
	cd $(BUILDDIR)/$(MINECRAFT) && pw modrinth export --pack-file ../pack/${MINECRAFT}/pack.toml

upload-modrinth:
	sed -i -e '/version =/ s/= .*/= "${VERSION}"/' pack/${MINECRAFT}/pack.toml
	make modrinth
	make curseforge
	make quilt-server
	ID=${ID} VERSION=${VERSION} LOADER=${LOADER} MINECRAFT=${MINECRAFT} MODRINTH_TOKEN=${MODRINTH_TOKEN} gradle modrinth

clean:
	-rm -rf $(BUILDDIR)/
	sed -i -e '/version =/ s/= .*/= "${VERSION}"/' ./pack/pack.toml
	-git gc --aggressive --prune


all: modrinth prism server clean