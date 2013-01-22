/**
 * Created with IntelliJ IDEA.
 * User: danilakolesnikov
 * Date: 1/18/13
 * Time: 3:08 PM
 * To change this template use File | Settings | File Templates.
 */
package com.grapefrukt.exporter.textures {
import com.grapefrukt.exporter.settings.Settings;

import flash.display.BitmapData;
import flash.geom.Rectangle;

public class FTCBitmapTextureInFolders extends FTCBitmapTexture {

    public function FTCBitmapTextureInFolders(name:String, bitmap:BitmapData, bounds:Rectangle, zIndex:int, isMask:Boolean = false) {
        super(name, bitmap, bounds, zIndex, isMask);
    }

    override public function getFilenameWithPathAndSuffix():String {
        return sheet.name + Settings.directorySeparator + fileSuffix + Settings.directorySeparator +sheet.name +"_" + name + extension;
    }
}
}
