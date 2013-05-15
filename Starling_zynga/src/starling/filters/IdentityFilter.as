/**
 Copyright 2013 Zynga Inc.
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 */

package starling.filters
{
    import flash.display3D.Context3D;
    import flash.display3D.Program3D;
    
    import starling.textures.Texture;

    /** This filter is only kept as a sample filter implementation you can learn from. It will
      * be removed with the next official Starling release! */
    public class IdentityFilter extends FragmentFilter
    {
        private var mShaderProgram:Program3D;
        
        public function IdentityFilter()
        {
            super();
        }
        
        public override function dispose():void
        {
            if (mShaderProgram) mShaderProgram.dispose();
            super.dispose();
        }
        
        protected override function createPrograms():void
        {
            var fragmentProgramCode:String =
                "tex oc, v0, fs0 <2d, clamp, linear, mipnone>"; // just forward texture color
            
            mShaderProgram = assembleAgal(fragmentProgramCode);
        }
        
        protected override function activate(pass:int, context:Context3D, texture:Texture):void
        {
            // already set by super class:
            // 
            // vertex constants 0-3: mvpMatrix (3D)
            // vertex attribute 0:   vertex position (FLOAT_2)
            // vertex attribute 1:   texture coordinates (FLOAT_2)
            // texture 0:            input texture
            
            context.setProgram(mShaderProgram);
        }
    }
}