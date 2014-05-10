{-# LANGUAGE MultiWayIf #-}

module TranslationOptimizer
  ( lstSqDistances
  ) where

import Data.Map (Map)
import Data.Maybe
import qualified Data.Map as Map
import qualified Data.Set as Set
import Data.Packed.Matrix
import Data.Packed.Vector
import Numeric.LinearAlgebra.Algorithms (linearSolveLS)


biject :: (Ord a) => [a] -> (a -> Int, Int -> a)
biject xs = (indexOf, aOfIndex)
  where
    uniqueAs = Set.toList . Set.fromList $ xs
    indexToAMap = Map.fromList $ zip [(0::Int)..] uniqueAs
    aToIndexMap = Map.fromList $ zip uniqueAs     [0..]
    get x = fromMaybe (error "biject") . Map.lookup x
    indexOf x = get x aToIndexMap
    aOfIndex x = get x indexToAMap



lstSqDistances :: (Ord a) => Map (a, a) Double -> Map a Double
lstSqDistances distMap = res
  where
    uniq = Set.toList . Set.fromList
    uniqueAs = uniq $ concat [ [a,b] | (a,b) <- Map.keys distMap ]
    (indexOf, aOfIndex) = biject uniqueAs

    pos = lstSqDistancesI (Map.mapKeys (\(a,b) -> (indexOf a, indexOf b)) distMap)
    res = Map.fromList $ zip (map aOfIndex [0..]) pos


lstSqDistancesI :: Map (Int, Int) Double -> [Double]
lstSqDistancesI distMap = points
  where
    dists = Map.toList distMap
    n = succ . maximum $ concat [ [i,j] | ((i,j),_) <- dists ]

    a = fromColumns . drop 1 . toColumns $ -- drop first col as we want x_0 = 0
          fromRows [ fromList $ mkRow (i,j) | ((i,j),_) <- dists ]

    -- Puts a -1 at position i and a +1 at position j
    mkRow (i,j) = [ (if | p == i    -> -1
                        | p == j    ->  1
                        | otherwise ->  0) | p <- [0..n-1] ]


    b = asColumn $ fromList [ d | (_, d) <- dists ]

    [x] = toColumns $ linearSolveLS a b
    points = 0.0 : toList x -- prepend a 0 for x_0