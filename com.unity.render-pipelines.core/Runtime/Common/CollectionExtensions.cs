using System;
using System.Collections.Generic;
using System.Diagnostics.CodeAnalysis;
using JetBrains.Annotations;

namespace UnityEngine.Rendering
{
    /// <summary>
    /// A set of extension methods for collections
    /// </summary>
    public static class CollectionExtensions
    {
        /// <summary>
        /// Removes a range of elements from the list.
        /// </summary>
        /// <param name="list">The list to remove the range</param>
        /// <param name="index">The zero-based starting index of the range of elements to remove</param>
        /// <param name="count">The number of elements to remove.</param>
        /// <typeparam name="TList">The type of the input list</typeparam>
        /// <typeparam name="TValue">The value type stored on the list</typeparam>
        /// <exception cref="ArgumentOutOfRangeException">index is less than 0. or count is less than 0.</exception>
        /// <exception cref="ArgumentException">index and count do not denote a valid range of elements in the list</exception>
        [CollectionAccess(CollectionAccessType.ModifyExistingContent)]
        public static void RemoveRange<TList, TValue>([DisallowNull] this TList list, int index, int count)
            where TList: IList<TValue>
        {
            // This branching is inlined at compilation
            if (typeof(TList) == typeof(List<TValue>))
            {
                // Reinterpret cast, this is safe because we checked the types before
                var castedList = __refvalue(__makeref(list), List<TValue>);
                castedList.RemoveRange(index, count);
            }
            else
            {
                if (index < 0)
                    throw new ArgumentOutOfRangeException(nameof(index));

                if (count < 0)
                    throw new ArgumentOutOfRangeException(nameof(count));

                if (list.Count - index < count)
                    throw new ArgumentException("index and count do not denote a valid range of elements in the list");

                for (var i = count; i > 0; --i)
                    list.RemoveAt(index);
            }
        }

        /// <summary>
        /// Removes a range of elements from the list.
        /// </summary>
        /// <param name="list">The list to remove the range</param>
        /// <param name="index">The zero-based starting index of the range of elements to remove</param>
        /// <param name="count">The number of elements to remove.</param>
        /// <typeparam name="TValue">The value type stored on the list</typeparam>
        /// <exception cref="ArgumentOutOfRangeException">index is less than 0. or count is less than 0.</exception>
        /// <exception cref="ArgumentException">index and count do not denote a valid range of elements in the list</exception>
        [CollectionAccess(CollectionAccessType.ModifyExistingContent)]
        public static void RemoveRange<TValue>([DisallowNull] this IList<TValue> list, int index, int count)
        {
            if (list is List<TValue> genericList)
            {
                genericList.RemoveRange<List<TValue>, TValue>(index, count);
            }
            else
            {
                list.RemoveRange<IList<TValue>, TValue>(index, count);
            }
        }
    }
}
