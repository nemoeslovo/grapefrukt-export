package com.grapefrukt.exporter.simple
{
	import com.grapefrukt.exporter.extractors.AnimationExtractor;
	import com.grapefrukt.exporter.extractors.TextureExtractor;
	import com.grapefrukt.exporter.textures.FTCBitmapTexture;
	import com.grapefrukt.exporter.textures.TextureSheet;
	import com.grapefrukt.support.MovieClipsLoaded;

	import org.hamcrest.assertThat;
	import org.hamcrest.object.equalTo;

	import flash.events.Event;

	public class FTCSimpleExportTest extends MovieClipsLoaded
	{
		private static const NUM_ROBOT_PARTS:Number = 14;
		private static const SCALE_RETINA:Number = 1;
		private static const SCALE_NON_RETINA:Number = .5;
		private static const COCOS_RETINA_EXT : String = "-hd";
		
		private static var export : FTCSimpleExport;

		[Before]
		public function setup() : void
		{
			export = new FTCSimpleExport(this, "robot");
		}

		[Test]
		public function should_export_one_asset_for_each_timeline_movieclip() : void
		{
			var loadedClass:Class = getLoadedClassNamed("RobotCharacterMc");
			
			AnimationExtractor.extract(export.animations, new loadedClass(), null, true, 1);
			var textureSheetRetina : TextureSheet = TextureExtractor.extract(new loadedClass(), null, false, null, true, SCALE_RETINA, FTCBitmapTexture, COCOS_RETINA_EXT);
			var textureSheetNonRetina : TextureSheet = TextureExtractor.extract(new loadedClass(), null, false, null, true, SCALE_NON_RETINA);

			export.texturesFile.add(textureSheetRetina);
			export.texturesArt.add(textureSheetRetina);
			export.texturesArt.add(textureSheetNonRetina);

			export.exportWithCompleteHandler(handleExportCompleteEvent);
		}

		private function handleExportCompleteEvent(event:Event) : void
		{
			assertThat(NUM_ROBOT_PARTS, equalTo(export.texturesArt.head.textures.length));
			assertThat(NUM_ROBOT_PARTS, equalTo(export.texturesFile.head.textures.length));
		}
	}
}

