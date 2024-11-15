export const idlFactory = ({ IDL }) => {
  return IDL.Service({ 'heartbeat' : IDL.Func([], [IDL.Text], ['query']) });
};
export const init = ({ IDL }) => { return []; };
