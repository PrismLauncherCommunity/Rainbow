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
	@echo "prism will make a prism zip file which contains the packwiz updater."
	@echo ""
	@echo "Technic will make a Technic pack zip"
	@echo ""
	@echo "All will make all packs it can"
	@echo ""
	
curseforge:
	@echo "Making Curseforge pack"
	packwiz curseforge export

modrinth:
	@echo "Making Modrinth pack"
	packwiz modrinth export

prism:
	@echo "Making Prism Launcher pack"
	7z d modpack-prism.zip ./meta/* -r
	7z d modpack-prism.zip ./meta/.minecraft -r
	7z a modpack-prism.zip ./meta/* -r
	7z a modpack-prism.zip ./meta/.minecraft -r
	7z d modpack-prism.zip ./meta/server -r

technic:
	@echo "Making Technic pack"
	-rm -rf .technic
	-cp -r ./meta/.minecraft .technic/
	cd .technic && java -jar packwiz-installer-bootstrap.jar https://gitlab.com/Merith-TK/modpack-template/-/raw/main/.minecraft/pack.toml && cd ..
	-cp ./meta/icon.png .technic/modpack.icon.png
	7z d modpack-technic.zip * -r
	7z a modpack-technic.zip .technic/* -r

server:
	@echo "Making Server pack"
	-rm quilt-installer-latest.jar
	wget -nc https://maven.quiltmc.org/repository/release/org/quiltmc/quilt-installer/latest/quilt-installer-latest.jar
	java -jar quilt-installer-latest.jar \
  	install server 1.19.2 \
  	--download-server
	-cp -r ./meta/server/. ./server/
	-cp ./meta/.minecraft/packwiz-installer-bootstrap.jar ./server/
	7z d modpack-server.zip ./server/* -r
	7z a modpack-server.zip ./server/* -r
	
clean:
	-rm quilt-installer-latest.jar
	-rm -rf .technic
	-rm -rf server
	-git gc --aggressive --prune

update:
	packwiz update -a

release:
	sed -i "s/version = \".*\..*\..*\"/version = \"$(VERSION)\"/" pack/pack.toml build.gradle
	gradle modrinth
	git push origin
	git push mirror

all: curseforge modrinth prism technic server clean