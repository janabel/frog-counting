interface UserInputProps {
  id: string;
  placeholder: string;
}

export function UserInput({ id, placeholder }: UserInputProps) {
  return <textarea id={id} placeholder={placeholder}></textarea>;
}
