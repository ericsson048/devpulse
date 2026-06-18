import ReactMarkdown from 'react-markdown';
import remarkGfm from 'remark-gfm';
import type { Components } from 'react-markdown';

interface Props {
  content: string;
}

const components: Components = {
  code({ className, children, ...props }) {
    const isInline = !className;
    if (isInline) {
      return <code className="px-1.5 py-0.5 rounded bg-gray-700 text-pink-300 text-sm" {...props}>{children}</code>;
    }
    return (
      <pre className="bg-[#0D1117] rounded-lg p-4 overflow-auto my-3 text-sm leading-relaxed">
        <code className={className} {...props}>{children}</code>
      </pre>
    );
  },
  h1: ({ children, ...props }) => <h1 className="text-xl font-bold mt-5 mb-2 text-white" {...props}>{children}</h1>,
  h2: ({ children, ...props }) => <h2 className="text-lg font-semibold mt-4 mb-2 text-white" {...props}>{children}</h2>,
  h3: ({ children, ...props }) => <h3 className="text-base font-semibold mt-3 mb-1.5 text-white" {...props}>{children}</h3>,
  p: ({ children, ...props }) => <p className="text-gray-300 leading-relaxed mb-3" {...props}>{children}</p>,
  ul: ({ children, ...props }) => <ul className="list-disc pl-5 mb-3 text-gray-300 space-y-1" {...props}>{children}</ul>,
  ol: ({ children, ...props }) => <ol className="list-decimal pl-5 mb-3 text-gray-300 space-y-1" {...props}>{children}</ol>,
  li: ({ children, ...props }) => <li {...props}>{children}</li>,
  blockquote: ({ children, ...props }) => (
    <blockquote className="border-l-4 border-indigo-500 pl-4 py-1 my-3 text-gray-400 italic bg-indigo-500/5 rounded-r-lg" {...props}>{children}</blockquote>
  ),
  a: ({ children, href, ...props }) => (
    <a href={href} className="text-indigo-400 hover:text-indigo-300 underline" target="_blank" rel="noopener noreferrer" {...props}>{children}</a>
  ),
  hr: () => <hr className="border-gray-700 my-4" />,
  table: ({ children, ...props }) => (
    <div className="overflow-auto my-3">
      <table className="min-w-full border-collapse border border-gray-700 text-sm" {...props}>{children}</table>
    </div>
  ),
  th: ({ children, ...props }) => <th className="border border-gray-700 px-3 py-2 bg-gray-800 text-gray-200 font-medium" {...props}>{children}</th>,
  td: ({ children, ...props }) => <td className="border border-gray-700 px-3 py-2 text-gray-300" {...props}>{children}</td>,
  strong: ({ children, ...props }) => <strong className="text-white font-semibold" {...props}>{children}</strong>,
  em: ({ children, ...props }) => <em className="text-gray-200" {...props}>{children}</em>,
};

export default function MarkdownRenderer({ content }: Props) {
  return (
    <ReactMarkdown remarkPlugins={[remarkGfm]} components={components}>
      {content}
    </ReactMarkdown>
  );
}
