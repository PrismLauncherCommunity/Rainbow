ID := rainbow
VERSION := develop
LOADER := quilt
MINECRAFT := 1.20.1

BUILDDIR=build/

$(BUILDDIR):
	mkdir -p $@

$(BUILDDIR)/server: | $(BUILDDIR)
	@echo "Installing quilt"
	wget -nc https://quiltmc.org/api/v1/download-latest-installer/java-universal -O $(BUILDDIR)/quilt-installer.jar
	cd $(BUILDDIR) && java -jar quilt-installer.jar \
		install server ${MINECRAFT} \
		--download-server
	-rm $(BUILDDIR)/quilt-installer.jar

$(BUILDDIR)/server/packwiz-installer-bootstrap.jar: | $(BUILDDIR)/server
	@echo "Preparing packwiz bootstrap"
	wget -nc https://github.com/packwiz/packwiz-installer-bootstrap/releases/download/v0.0.3/packwiz-installer-bootstrap.jar -P $(BUILDDIR)/server

$(BUILDDIR)/server/eula.txt: | $(BUILDDIR)/server/packwiz-installer-bootstrap.jar
	@echo "Agreeing to EULA"
	echo "eula=true" > $(BUILDDIR)/server/eula.txt

update-packwiz:
	@echo "Update packwiz"
	go install github.com/packwiz/packwiz@latest

download-mods: | $(BUILDDIR)/server/packwiz-installer-bootstrap.jar update-packwiz
	@echo "Download server mods"
	packwiz --pack-file ./pack/${MINECRAFT}/pack.toml serve &
	@sleep 1
	cd $(BUILDDIR)/server && java -jar packwiz-installer-bootstrap.jar -g -s server http://0.0.0.0:8080/pack.toml
	pkill packwiz 

prepare-server: download-mods $(BUILDDIR)/server/eula.txt

run-server: prepare-server
	@echo "Starting Dev Server"
	cd $(BUILDDIR)/server && java -jar quilt-server-launch.jar nogui

export-mrpack:
	@echo "Making ${MINECRAFT} Modrinth pack"
	-mkdir $(BUILDDIR)
	cd $(BUILDDIR) && pw modrinth export --pack-file ../pack/${MINECRAFT}/pack.toml

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