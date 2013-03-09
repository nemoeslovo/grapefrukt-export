/**
 * Created with IntelliJ IDEA.
 * User: danilakolesnikov
 * Date: 1/17/13
 * Time: 6:23 PM
 * To change this template use File | Settings | File Templates.
 */
package com.grapefrukt.exporter.extractors {

import com.grapefrukt.exporter.simple.*;
import com.grapefrukt.exporter.textures.*;

import flash.display.DisplayObjectContainer;

public class FTCExtractor {
    private static function extract( root                : DisplayObjectContainer
                                   , frameRate           : Number
                                   , classToExport       : Class
                                   , xmlPrefix           : String = "object"
                                   , scaleIpadFromRetina : Number = 1.5
                                   , imageClass          : Class  = null) :void {
        var SCALE_NON_RETINA : Number       =  0.5;
        var SCALE_RETINA     : Number       =  2                   * SCALE_NON_RETINA;
        var IPAD_NON_RETINA  : Number       =  scaleIpadFromRetina * SCALE_RETINA;
        var IPAD_RETINA      : Number       =  2                   * IPAD_NON_RETINA;

        var COCOS_RETINA_EXT    : String = "-hd";
        var IPAD_NON_RETINA_EXT : String = "-ipad";
        var IPAD_RETINA_EXT     : String = "-ipadhd";


        var export:FTCSimpleExport = new FTCSimpleExport(root, xmlPrefix, frameRate);

        AnimationExtractor.extract( export.animations   //animation collection
                                  , new classToExport   //class to export
                                  , null                //array of ignored parts
                                  , true                //convert pixels to point
                                  , 1);                 //animation scale 1factor (use if low resolution of texture export with differ scale than 1)

        var retina : TextureSheet
                = TextureExtractor.extract( new classToExport   //class to extract
                                          , null                //array of ignored pictures
                                          , true                //respect scale
                                          , null                //returned class (default just TextureSheet
                                          , true                //convert pixels to points
                                          , SCALE_RETINA        //textures scale
                                          , imageClass          //textures class (FTCBitmapTexture respect to -hd suffix)
                                          , COCOS_RETINA_EXT);  //file suffix

        var nonRetina:TextureSheet = TextureExtractor.extract( new classToExport
                                                             , null
                                                             , false
                                                             , null
                                                             , true
                                                             , SCALE_NON_RETINA);
        var ipadNonRetina:TextureSheet = TextureExtractor.extract( new classToExport
                                                                 , null
                                                                 , false
                                                                 , null
                                                                 , true
                                                                 , IPAD_NON_RETINA
                                                                 , imageClass
                                                                 , IPAD_NON_RETINA_EXT);
        var ipadRetina :TextureSheet = TextureExtractor.extract( new classToExport
                                                               , null
                                                               , false
                                                               , null
                                                               , true
                                                               , IPAD_RETINA
                                                               , imageClass
                                                               , IPAD_RETINA_EXT);

        export.texturesFile.add(retina);

        export.texturesArt.add(retina);
        export.texturesArt.add(nonRetina);
        export.texturesArt.add(ipadNonRetina);
        export.texturesArt.add(ipadRetina);

        export.export();
    }

    public static function extractForIOS( root                : DisplayObjectContainer
                                        , frameRate           : Number
                                        , classToExport       : Class
                                        , xmlPrefix           : String = "object"
                                        , scaleIpadFromRetina : Number = 1.5) : void {
        FTCExtractor.extract(root, frameRate, classToExport, xmlPrefix, scaleIpadFromRetina, FTCBitmapTexture);
    }

    public static function extractForIosWithPrefixes( root                : DisplayObjectContainer
                                                    , frameRate           : Number
                                                    , classToExport       : Class
                                                    , xmlPrefix           : String = "object"
                                                    , scaleIpadFromRetina : Number = 1.5) : void {
        FTCExtractor.extract(root, frameRate, classToExport, xmlPrefix, scaleIpadFromRetina, FTCBitmapTextureInFolders);
    }

    }
}
