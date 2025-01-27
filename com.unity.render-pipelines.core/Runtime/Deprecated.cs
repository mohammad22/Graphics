using System;
using System.Collections.Generic;
using System.Linq;
using System.Reflection;

namespace UnityEngine.Rendering
{
    public abstract partial class VolumeDebugSettings<T>
    {
        static List<Type> s_ComponentTypes;
        /// <summary>List of Volume component types.</summary>
        [Obsolete("Please use volumeComponentsPathAndType instead, and get the second element of the tuple", false)]
        public static List<Type> componentTypes
        {
            get
            {
                if (s_ComponentTypes == null)
                {
                    s_ComponentTypes = VolumeManager.instance.baseComponentTypeArray
                        .Where(t => !t.IsDefined(typeof(HideInInspector), false))
                        .Where(t => !t.IsDefined(typeof(ObsoleteAttribute), false))
                        .OrderBy(t => ComponentDisplayName(t))
                        .ToList();
                }
                return s_ComponentTypes;
            }
        }

        /// <summary>Returns the name of a component from its VolumeComponentMenuForRenderPipeline.</summary>
        /// <param name="component">A volume component.</param>
        /// <returns>The component display name.</returns>
        [Obsolete("Please use componentPathAndType instead, and get the first element of the tuple", false)]
        public static string ComponentDisplayName(Type component)
        {
            if (component.GetCustomAttribute(typeof(VolumeComponentMenuForRenderPipeline), false) is VolumeComponentMenuForRenderPipeline volumeComponentMenuForRenderPipeline)
                return volumeComponentMenuForRenderPipeline.menu;

            if (component.GetCustomAttribute(typeof(VolumeComponentMenu), false) is VolumeComponentMenuForRenderPipeline volumeComponentMenu)
                return volumeComponentMenu.menu;

            return component.Name;
        }
    }
}
