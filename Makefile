default:
	@echo "No Default make command configured"
	@echo "Please use either"
	@echo "   - make curseforge"
	@echo "   - make modrinth"
	@echo "   - make polymc"
	@echo "   - make technic"
	@echo "   - make all"
	@echo ""
	@echo "Curseforge will make a curseforge compatible zip"
	@echo ""
	@echo "Modrinth will make a Modrinth compatible mrpack"
	@echo ""
	@echo "PolyMC will make a PolyMC zip file which contains the packwiz updater."
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
	7z d modpack-polymc.zip ./prism/* -r
	7z d modpack-polymc.zip ./prism/.minecraft -r
	7z a modpack-polymc.zip ./prism/* -r
	7z a modpack-polymc.zip ./pack/.minecraft -r
	7z d modpack-polymc.zip ./pack/.minecraft/mods ./pack/.minecraft/pack.toml ./pack/.minecraft/index.toml -r

technic:
	@echo "Making Technic pack"
	mkdir -p build
	-cp -r ./pack/.minecraft ./build/.technic
	-cp ./pack/icon.png ./build/.technic/
	cd ./build/.technic && java -jar packwiz-installer-bootstrap.jar https://zekesmith.github.io/HexMC/pack/.minecraft/pack.toml -g && cd ..
	-rm -rf ./build/.technic/packwiz*
	7z d ./build/modpack-technic.zip ./build/* -r
	7z a ./build/modpack-technic.zip ./build/.technic/* -r

servers:
	-rm quilt-installer-latest.jar
	-rm -v server/!("start.sh"|"start.bat")
	wget https://maven.quiltmc.org/repository/release/org/quiltmc/quilt-installer/latest/quilt-installer-latest.jar
	java -jar quilt-installer-latest.jar \
  	install server 1.18.2 \
  	--download-server
	cd server && wget https://github.com/packwiz/packwiz-installer/releases/download/v0.5.4/packwiz-installer.jar
	
	
clean:
	-rm quilt-installer-latest.jar
	-rm -v server/!("start.sh"|"start.bat")
	-rm -rf ./build/.technic
	-git gc --aggressive --prune

update:
	packwiz update -a

release:
	gradle modrinth
	sed -i "s/version = \".*\..*\..*\"/version = \"$(VERSION)\"/" pack/pack.toml build.gradle
	git push origin
	git push mirror

all: curseforge modrinth polymc technic server clean