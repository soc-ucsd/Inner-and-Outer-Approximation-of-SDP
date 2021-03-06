function [Obj,elapsedTime]=StableSets_BFW2ColsGen_PreData(Adj,P,At,b,c,K)

    T1 = tic;
    elapsedTime = [];
    
    epsilon = 0.001;
    Max_Iter = 40; Iter = 1;
    dim_mat = width(Adj);%dimension of design matirx
    
    Obj = [];
    At_new = At;
    b_new = b;
    c_new = c;
    K_new = K;
    
    time = [];
    NumOfCut = 2;
    while true
    
%         [x,y,info]=sedumi(At_new,b_new,c_new,K_new);
%         X = reshape(y,[dim_mat,dim_mat]);
        
         if Iter ==1
             T1 = tic;
             prob1 = convert_sedumi2mosek(At_new,b_new,c_new,K_new);
             elapse = toc(T1);
             time = [time,elapse];
         else
             %T1 = tic;
            
             testK = K;
             testK.s = [NumOfCut];
             prob2 = convert_sedumi2mosek_modified(At_new(:,[1:K.l+K.f,pre+1:end]),b_new,c_new([1:K.l+K.f,pre+1:end]),testK,pre,NumOfpres);

             
             prob1.bardim =[prob1.bardim, prob2.bardim];
             prob1.bara.subi = [prob1.bara.subi,prob2.bara.subi];
             prob1.bara.subj = [prob1.bara.subj,prob2.bara.subj];
             prob1.bara.subk = [prob1.bara.subk,prob2.bara.subk];
             prob1.bara.subl = [prob1.bara.subl,prob2.bara.subl];
             prob1.bara.val = [prob1.bara.val,prob2.bara.val];

         end
        [rcode1, res1] = mosekopt('minimize info', prob1);
        Obj = [Obj,res1.sol.itr.pobjval];
        X = reshape(res1.sol.itr.y,[dim_mat,dim_mat]);
        elptime = toc(T1);
        elapsedTime = [elapsedTime,elptime];
        
        [V,D] = eig(X);
        [d, I]=sort(diag(D));
        if d(1)>=0 || abs(d(1))<=epsilon || Iter>=Max_Iter %get PSD 
            PSD = true;
            break;
        end
        v = V(:,I(1:NumOfCut));
        
        NewV = kron(v',v');
        
        pre = width(At_new);
        NumOfpres = length(K_new.s);
        
        At_new = [At_new,-NewV'];
        c_new = [c_new; sparse(NumOfCut^2,1)];
        K_new.s = [K_new.s,NumOfCut];
        
        Iter = Iter +1;
    
    
    end
    
    disp('wait');
end