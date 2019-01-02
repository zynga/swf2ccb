**Please note:** This project is deprecated at Zynga and is no longer maintained.

---

<ul>
    <li><a href='#SwftoCCBConverter-Overview'>Overview</a></li>
    <li><a href='#SwftoCCBConverter-Installation'>Installation</a></li>
    <li><a href='#SwftoCCBConverter-PreppingtheFlashfiles'>Prepping the Flash files</a></li>
    <li><a href='#SwftoCCBConverter-Workflow'>Workflow</a></li>
    <li><a href='#ZyngaStarling'>Zynga Starling/Starling Output</a></li>
    <li><a href='#SwftoCCBConverter-ContactInfo'>Contact Info</a></li>
</ul></div>


<h1><a name="SwftoCCBConverter-Overview"></a>Overview</h1>

<p>This tool is an AIR app that scrapes the animation data from swf files using a modified Starling Library and outputs it to a ccb format that can be read and edited by <a href="http://cocosbuilder.com/" class="external-link" rel="nofollow">CocosBuilder</a>, an open source mobile development tool. The tool is useful for teams that have a lot of flash assets (published in swfs) created already and wish to minimize the work done to port their assets to a mobile game.</p>

<h1><a name="SwftoCCBConverter-Installation"></a>Installation</h1>

<p> It should work with the newest version of Air, but if not, try downloading the&nbsp;<a href="https:/https://github.com/zynga/swf2ccb/blob/master/air3-5_mac.dmg" class="external-link" rel="nofollow">air3-5_mac.dmg</a>&nbsp;for the a working tool with Adobe AIR (if you have a higher version installed, please uninstall it and install AIR 3.5).</p>

<p>There is a jsfl script in the repo that you can run on your fla files to export all the movieClip symbols and to identify all the shape/shape tweens that need to be changed so the outputted swf can be used optimally with swf2Cocos. To run it, open the Flash file and do Command > Run Command and select exportAndID.jsfl. The movie clips are then exported, and the output displays the animations that will cause problems: <img src="http://content.screencast.com/users/edisontung/folders/Jing/media/1bda6e79-989f-4151-ac49-9551f676d8a4/00000082.png" /> </p>

<p>The air app is located here:<a href="https://github.com/zynga/swf2ccb/blob/master/flexPreviewTool/swf2ccb.air" class="external-link" rel="nofollow">&nbsp;https://github.com/zynga/swf2ccb/blob/master/flexPreviewTool/swf2ccb.air</a>. Just download and run it.</p>

<h1><a name="SwftoCCBConverter-PreppingtheFlashfiles"></a>Prepping the Flash files</h1>

<p>First, there needs to be a master symbol that has the same name as the file name (check out picture below). This is to ensure that every symbol is referenced and can be more easily accessed by the tool to get the animation data. Every symbol also needs to be exported, and each animation should only animate symbols (rather than animating shapes that are in different layers). Sometimes it's not possible to get animation data from Flash Shapes (or it may be possible, and we haven't figured it out yet). <span class="image-wrap" style=""><img src="http://content.screencast.com/users/edisontung/folders/Jing/media/bf8797d3-8c25-4ce4-9de6-460bd6fad48c/00000052.png" width="1200pxpx" style="border: 1px solid black" /></span></p>

<p>Also, the ccb files generated are just for CocosBuilder. It is at least 20x bigger than the published size of the ccbi files that are put on the device. Please do not freak out when you see that the ccb files are a few MBs, they will be much smaller on the device<br/>
For more info about prepping the flash files, please refer to <a href="https://zyntranet.apps.corp.zynga.com/display/ESlotsMobile/FLASH+TO+CCB+FLEX+TOOL" class="external-link" rel="nofollow">this page done by the Austin Team</a></p>

<h1><a name="SwftoCCBConverter-Workflow"></a>Workflow</h1>

<ol>
	<li>After you clone the repo from GitHub (or just download the tool itself), if there are any previous versions installed, please close it (if you do not know how to use git, refer to <a href="http://www.siteground.com/tutorials/git/commands.htm" class="external-link" rel="nofollow">this link</a>, or just google it yourself). Then, start off by running the air app, which looks like this:<br/>
<span class="image-wrap" style=""><img src="http://content.screencast.com/users/edisontung/folders/Jing/media/9efc50e4-0cd6-4732-b8cd-cfdb4acd11c3/00000066.png" style="border: 1px solid black" /></span></li>
	<li>&nbsp;Once you run it, the top of the app looks like this starting off:&nbsp;<br/>
<span class="image-wrap" style=""><img src="http://content.screencast.com/users/edisontung/folders/Jing/media/a684430c-8d14-4aa2-89e9-6f520039fc14/00000080.png" width="1000px" style="border: 1px solid black" /></span>
	<ol>
		<li>The different options are as such:
		<ol>
			<li>Load File - Load a single swf</li>
			<li>Load Directory - Load a whole directory of swfs</li>
			<li>Bitmap Quality - The highest resolution that you would like your game at. This ensures that your bitmaps are at a high enough quality to not be pixelated for the highest resolution game.</li>
			<li>Basic Game Device - This is the lowest resolution you would like it at. CocosBuilder has the options to scale up everything for you, so assets are created with numbers to fit with the lowest resolution, and scaled up to the correct resolution. CocosBuilder doesn't scale down from 1.0</li>
			<li>save options: 
				<ol> 
					<li> There are a few preset destinations you can choose to output to </li>
					<li> The directories that files are saved to are only saved if you want them to be saved. </li>
					<li> The .ccb, .star, and .json files are only saved out if you want them. </li>
				</ol>
			</li>
		</ol>
		</li>
	</ol>
	</li>
	<li>&nbsp;After you load a file, the animation is displayed on the tool (animation not shown in this screenshot). Then it asks for the location for which to save the ccb and bitmap files (if that option is unchecked).&nbsp;<br/>
<span class="image-wrap" style=""><img src="http://content.screencast.com/users/edisontung/folders/Jing/media/3d8fc2d8-6904-4fca-9c53-2fbfd5de3db0/00000065.png" width="750px" style="border: 1px solid black" /></span></li>
	<li>If your position scale and your bitmap scale were different, make sure you pick the right resolution in CocosBuilder (File &gt; Publish Settings...). Pick it based on the resolution of the bitmaps<br/>
<span class="image-wrap" style=""><img src="http://content.screencast.com/users/edisontung/folders/Jing/media/a0250e9b-2133-4e6f-8bec-97efa972a8e0/00000067.png" height="450px" style="border: 1px solid black" /></span></li>
	<li>&nbsp;Once the ccb files and bitmaps are outputted, you can view them in CocosBuilder&#33;<br/>
<span class="image-wrap" style=""><img src="http://content.screencast.com/users/edisontung/folders/Jing/media/7c068f66-8dff-4f93-82bf-670c56572230/00000068.png" style="border: 1px solid black" /></span></li>
	<li>&nbsp;The ccb and bitmap files are where you saved them. There is also a .json file that contains all the animation data in json format if you're interested in reading that, <a href='#SwftoCCBConverter-JsonDocumentation'>click here</a><br/>
<span class="image-wrap" style=""><img src="http://content.screencast.com/users/edisontung/folders/Jing/media/f1f6a612-007f-4757-a92c-36ca451ae502/00000069.png" height="400px" style="border: 1px solid black" /></span> <span class="image-wrap" style=""><img src="http://content.screencast.com/users/edisontung/folders/Jing/media/43b346e6-b6dd-4cb9-9eb1-af025dd90ac2/00000070.png" height="400px" style="border: 1px solid black" /></span></li>
</ol>

<div id="full-height-container">


    
    <h1 id="title-heading" class="pagetitle">


                            


		<span id="title-text">
					           <a name='ZyngaStarling'>Zynga Starling/Starling Output</a>
    				</span>
    </h1>


<div>
<ul>
    <li><a href='#SwftoCCBConverter-ZStarlingOverview'>Overview</a></li>
    <li><a href='#SwftoCCBConverter-UseofStarling'>Use of Starling</a></li>
    <li><a href='#SwftoCCBConverter-JsonDocumentation'>Json Documentation</a></li>
</ul></div>

<h1><a name="SwftoCCBConverter-ZStarlingOverview"></a>Overview</h1>

<p>There is a modified version of <a href="http://gamua.com/starling/" class="external-link" rel="nofollow">Starling</a> that I've been developing so that animation data can be obtained from swf files so they can be rendered on GPU. The repo is <a href="https://github.com/zynga/swf2ccb/tree/master/Starling_zynga" class="external-link" rel="nofollow">here</a> as well as included in this project.</p>

<h1><a name="SwftoCCBConverter-UseofStarling"></a>Use of Starling</h1>

<p>To output the .star or .json file using the tool, just check the corresponding boxes and specify where you would like the output. Refer to <a href='#SwftoCCBConverter-Workflow'>Workflow</a> for more details. </p>

<p>Here are some chunks of code from the tool that demonstrates how you can use Starling to get a starling object to display on GPU.</p>

<p>First, you initialize Starling by passing in the flash Stage on which you wish to display the starling objects.<br/>

<pre><code>private function init():void {
		var s:Starling = new Starling(starling.display.Sprite, this.systemManager.stage);
		s.makeCurrent();</code></pre>


<p>Also, make sure to make a new LoaderContext object so that the bytes can be loaded correctly and the symbols saved. <span class="image-wrap" style=""><pre><code>private var context:LoaderContext = new LoaderContext(false, new ApplicationDomain(ApplicationDomain.currentDomain));</code></pre><br/>
Given the native path of the swf file, you set up the loading process by loading a Flash URLRequest using a Flash URLLoader. This is the how swf files are loaded using the Flash Library. If this does not work, please refer to the <a href="http://help.adobe.com/en_US/FlashPlatform/reference/actionscript/3/index.html" class="external-link" rel="nofollow">Flash Documentation</a>.<br/>
<span class="image-wrap" style=""><pre><code>public function loadAssetFile(path:String):void {
	clearAll();
	m_currentPath = path;
	m_currentFileName = getFileName(path);
	var loader:URLLoader = new URLLoader();
	loader.dataFormat = URLLoaderDataFormat.BINARY;
	var urlReq:URLRequest = new URLRequest("file://" + path);
	loader.addEventListener(flash.events.Event.COMPLETE, loadBytes);
	loader.load(urlReq);
}
</code></pre></span><br/>
The reason for the listener in the code above is that loading files in flash is an asynchronous operation, so listeners need to be used.<br/>
So, once the file is loaded, you load the bytes of the file into a ByteArray as such:<br/>
<span class="image-wrap" style=""><pre><code>private function loadBytes(event:flash.events.Event):void {
	var uloader:URLLoader = URLLoader(event.target);
	var loader:Loader = new Loader();
	var bytes:ByteArray = ByteArray(event.target.data);
	uloader.removeEventListener(flash.events.Event.COMPLETE, loadBytes);
	var loaderInfo:LoaderInfo = loader.contentLoaderInfo;
	loaderInfo.addEventListener(flash.events.Event.COMPLETE, loadDone);
	loader.loadBytes(bytes, context);
}
</code></pre></span></p>

<p>Once the bytes are loaded into the byte array, this is what you can do. I'll explain part by part&nbsp;<br/>
<span class="image-wrap" style=""><pre><code>192	var asset:Asset;
193
194	// Register shared symbols
195	var url:String = m_currentPath;
196	var fileName:String = getFileName(url);
197	var rootSymbolName:String = fileName;
198	var cl:Class = context.applicationDomain.getDefinition(rootSymbolName) as Class;
199	var dispObj:flash.display.DisplayObject = flash.display.DisplayObject(new cl());
200
201	var num:Number = 2.2 * Math.pow(0.5, bitmapQ.selectedIndex);
202	if (num && num != 0) {
203		Asset.drawScale = num;
204	}
205
206	Asset.quality = Math.pow(2, mDefaultQuality - quality.value);
207	
208	asset = Asset.fromDisplayObject(dispObj, fileName, s_sharedContext, m_shared, false);
209		
210	registerStarlingAsset(asset);
211		
212	m_asset = asset;
213
214	m_currentObject = m_asset.createInstance(asset.rootSymbolName, s_textureCache);
215				
216	m_currentObject.x = width/2;
217	m_currentObject.y = height/2;
218					
219	Starling.current.stage.addChild(m_currentObject);</code></pre></span><br/>
on Line 196, getFileName gets the name of the swf file (it's a local method that's easy to write). This is so we can do the next part, which is:</p>

<p>context.applicationDomain.getDefinition(rootSymbolName) as Class gets the class object of the root object that refers to each symbol in the swf file. This is why you need the LoaderContext object.</p>

<p>Line 199 creates a new instance of the root object so that all the assets are created and can be displayed.</p>

<p>Line 208 is what creates an asset that keeps track of all the symbols</p>

<p>Line 210 registers all the asset names so that they can be referred to by symbol names.</p>

<p>Line 214 is how you create a Starling&nbsp;DisplayObject that can be put on&nbsp;the Starling Stage (initialized in Starling's init).</p>

<p>Line 219 shows you how to put it on the Starling Stage (can't put it on the Flash Stage because it's not a Flash&nbsp;DisplayObject)</p>

<p>To output the json and the bitmaps, do these commands:<br/>
<span class="image-wrap" style=""><pre><code>m_asset.saveJson(ccbPath);
m_asset.saveBinary(ccbPath);
				
var json:Object = m_asset.toJSON();
			
m_asset.saveAllBitmaps(ccbPath+origPathToBm);</code></pre></span></p>

<p>saveJson saves out the json data (described below).</p>

<p>saveBinary saves out a binary version of the file (with .star extension). This can be loaded back into Starling to be displayed in Starling.</p>

<p> To load the binary file back into Starling, you can do something like below: </p>

<pre><code>var loader:AssetLoader = new AssetLoader();
loader.load("…/fileName.star");
m_currentObject = loader.asset.createInstance(asset.rootSymbolName, s_textureCache);
Starling.current.stage.addChild(m_currentObject);
</code></pre>

<p>saveAllBitmaps saves out the bitmap files to the specified path.</p>


<h1><a name="SwftoCCBConverter-JsonDocumentation"></a>Json Documentation</h1>



<p>Here's a basic breakdown of how the json files look. It is a dictionary of dictionaries (and of more dictionaries for certain properties). A more detailed description with a sample file will follow after this initial screenshot</p>




<p><span class="image-wrap" style=""><img src="http://content.screencast.com/users/edisontung/folders/Jing/media/58f81175-aaad-4d4d-b02d-d2b30008bb13/00000057.png" style="border: 1px solid black" /></span></p>




<p>So how the json file is generated is as such:</p>



<p>First comes the dictionary of bitmaps, with the keys being the bitmap names:</p>




<p><span class="image-wrap" style=""><img src="http://content.screencast.com/users/edisontung/folders/Jing/media/de17a6e1-3103-4031-8ca2-bab4cad3a89d/00000058.png" style="border: 1px solid black" /></span></p>




<p>With each bitmap, there is a bitmap name that is associated with each bitmap. This is also the name of the png that is generated. That way, the asset and the ccb can refer to the pngs. The width and height of the bitmaps are included so that the correctly sized png can be generated when the pngs are generated</p>



<p>The next part of the json is the dictionary for all the symbols. These are the same symbol names that you see in the flash file.</p>


<p><span class="image-wrap" style=""><img src="http://content.screencast.com/users/edisontung/folders/Jing/media/e0c42016-34a5-4686-ab47-d4e64c9bb0a4/00000059.png" style="border: 1px solid black" /></span></p>




<p>In this example, you see the symbol name "RobotCharacterMc". That is the same as the export name in the flash file. There are 4 different values for the type of the symbol. "image", "text", "anim", and "sprite". An "image" is a bitmap, "text" is a textfield, "anim" means that it's a movieClip with animations, and "sprite" means that it's a normal sprite with no animations, just maybe children.</p>

<p>In each symbol, if there are any children, then there is an array of children. The highlighted box shows what one child entry looks like. The child entry contains a lot of the basic information needed that's not stored with its symbol (i.e. x, y coordinates, scale, skew).</p>



<p>The next part of each symbol entry is the animation array:</p>


<p><span class="image-wrap" style=""><img src="http://content.screencast.com/users/edisontung/folders/Jing/media/56487eed-07cd-430c-9718-fd8c2d06e4c7/00000060.png" style="border: 1px solid black" /></span></p>

<p>In the animation dictionary, the thing to note is how it's structured. At each index, there is a "tracks" object that keeps track of all the animation tracks associated with this symbol's children. Each animation track (highlighted in the picture) has a key that represents the property that is being changed. In each animation track, there are 2 dictionaries, one that says "start" and one that says "end". The "start" dictionary keeps track of the start keyframe and start value of each keyframe (estimated, not exactly what flash has), and the "end" dictionary keeps track of the end keyframe and end value of each keyframe. The keyframe and value in each dictionary are stored in the "values" and "frames" dictionaries, respectively.</p>



<p>Finally, there is basic information on the asset:</p>


<p><span class="image-wrap" style=""><img src="http://content.screencast.com/users/edisontung/folders/Jing/media/3b0ef8df-db7f-4201-9002-29d75441ab42/00000062.png" style="border: 1px solid black" /></span></p>


<p>The "rootObject" entry describes information about the rootObject. The "symbolName" here should match the name of the swf file</p>

<p>The "fileVer" describes the version of the asset that is being used (this value is passed in).</p>

<p>The "isShared" property describes whether or not the bitmaps and Starling assets are kept so that they can be shared with other Starling assets that are created in different runs of the program.</p>
                        
    
    
    <!-- end system javascript resources -->
</div>

<h1><a name="SwftoCCBConverter-ContactInfo"></a>Contact Info</h1>

<p>That's more or less it. If there are any issues, please let me know&#33;</p>

<p>email:&nbsp;<a href="mailto:etung@zynga.com" class="external-link" rel="nofollow">etung@zynga.com</a></p>

<p>skype: zynga.edison</p>
    
    <!-- end system javascript resources -->
</div>
</body>
