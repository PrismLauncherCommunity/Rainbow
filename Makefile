ID=rainbow
VERSION=develop
LOADER=fabric
MINECRAFT=1.20.1

BUILDDIR=build

$(BUILDDIR)/$(MINECRAFT):
	mkdir -p $@/$(MINECRAFT)

$(BUILDDIR)/$(MINECRAFT)/server: | $(BUILDDIR)/$(MINECRAFT)
	@echo "Installing Fabric"
	mkdir -p $(BUILDDIR)/$(MINECRAFT)/server
	wget -nc https://maven.fabricmc.net/net/fabricmc/fabric-installer/0.11.2/fabric-installer-0.11.2.jar -O $(BUILDDIR)/fabric-installer.jar
	cd $(BUILDDIR) && java -jar fabric-installer.jar \
		server -dir $(MINECRAFT)/server -mcversion ${MINECRAFT} -downloadMinecraft
	-rm $(BUILDDIR)/fabric-installer.jar

$(BUILDDIR)/$(MINECRAFT)/server/packwiz-installer-bootstrap.jar: | $(BUILDDIR)/$(MINECRAFT)/server
	@echo "Preparing packwiz bootstrap"
	wget -nc https://github.com/packwiz/packwiz-installer-bootstrap/releases/download/v0.0.3/packwiz-installer-bootstrap.jar -P $(BUILDDIR)/$(MINECRAFT)/server

$(BUILDDIR)/$(MINECRAFT)/server/eula.txt:
	@echo "Agreeing to EULA"
	echo "eula=true" > $(BUILDDIR)/$(MINECRAFT)/server/eula.txt

update-packwiz:
	@echo "Update packwiz"
	go install github.com/packwiz/packwiz@latest

serve-mods: | update-packwiz
	@echo "Download server mods"
	-pkill packwiz
	packwiz --pack-file ./pack/${MINECRAFT}/pack.toml serve &
	@sleep 1

prepare-server: serve-mods $(BUILDDIR)/$(MINECRAFT)/server/packwiz-installer-bootstrap.jar

run-server: prepare-server $(BUILDDIR)/$(MINECRAFT)/server/eula.txt
	@echo "Starting Dev Server"
	cd $(BUILDDIR)/$(MINECRAFT)/server && java -jar packwiz-installer-bootstrap.jar -g -s server http://0.0.0.0:8080/pack.toml
	cd $(BUILDDIR)/$(MINECRAFT)/server && java -jar fabric-server-launch.jar nogui || echo "done"
	-pkill packwiz

export-mrpack: $(BUILDDIR)/$(MINECRAFT)
	@echo "Making ${MINECRAFT} Modrinth pack"
	sed -i -e '/version =/ s/= .*/= "${VERSION}"/' pack/${MINECRAFT}/pack.toml
	cd $(BUILDDIR)/$(MINECRAFT) && packwiz modrinth export --pack-file ../../pack/${MINECRAFT}/pack.toml

upload-modrinth: export-mrpack
	ID=${ID} VERSION=${VERSION} LOADER=${LOADER} MINECRAFT=${MINECRAFT} MODRINTH_TOKEN=${MODRINTH_TOKEN} gradle modrinth

clean:
	-pkill packwiz
	-rm -rf $(BUILDDIR)/
	sed -i -e '/version =/ s/= .*/= "${VERSION}"/' ./pack/$(MINECRAFT)/pack.toml
	-git gc --aggressive --prune


all: modrinth prism server clean