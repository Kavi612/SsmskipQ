import { motion, useReducedMotion } from 'framer-motion';
import food1 from '../../assets/collage-food-1.png';
import food2 from '../../assets/collage-food-2.png';
import food3 from '../../assets/collage-food-3.png';
import food4 from '../../assets/collage-food-4.png';
import styles from './FoodCollage.module.css';

const FOODS = [
  { src: food1, rotate: -3, delay: 0, duration: 5.2, zIndex: 1 },
  { src: food2, rotate: 2, delay: 0.8, duration: 5.9, zIndex: 3 },
  { src: food3, rotate: -2, delay: 1.6, duration: 6.3, zIndex: 2 },
  { src: food4, rotate: 3, delay: 2.4, duration: 5.6, zIndex: 4 },
] as const;

const FoodCollage = () => {
  const reduceMotion = useReducedMotion();

  return (
    <div className={styles.collage} aria-hidden="true">
      {FOODS.map(({ src, rotate, delay, duration, zIndex }, index) => (
        <motion.img
          key={index}
          src={src}
          alt=""
          className={styles.food}
          style={{ zIndex, rotate: `${rotate}deg` }}
          animate={
            reduceMotion
              ? undefined
              : {
                  y: [0, -8, 0],
                }
          }
          transition={
            reduceMotion
              ? undefined
              : {
                  duration,
                  delay,
                  repeat: Infinity,
                  ease: 'easeInOut',
                }
          }
        />
      ))}
    </div>
  );
};

export default FoodCollage;
