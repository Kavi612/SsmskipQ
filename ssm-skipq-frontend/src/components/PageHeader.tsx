import { Link } from 'react-router-dom';
import type { ReactNode } from 'react';
import { ArrowLeft } from 'lucide-react';
import styles from './PageHeader.module.css';

interface PageHeaderProps {
  title: string;
  backTo?: string;
  rightSlot?: ReactNode;
}

const PageHeader = ({
  title,
  backTo = '/student',
  rightSlot,
}: PageHeaderProps) => {
  return (
    <header className={styles.header}>
      <Link to={backTo} className={styles.backBtn} aria-label="Go back">
        <ArrowLeft size={22} />
      </Link>
      <h1 className={styles.title}>{title}</h1>
      <div className={styles.right}>
        {rightSlot ?? <span className={styles.spacer} />}
      </div>
    </header>
  );
};

export default PageHeader;
